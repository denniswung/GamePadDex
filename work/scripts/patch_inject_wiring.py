import io, os, sys

JAVA = r"""import android.os.IBinder;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.reflect.Method;

/**
 * Root-level scroll injector (ACTION_SCROLL / SOURCE_MOUSE), fed by gpminput
 * over a pipe:
 *   app_process -Djava.class.path=/data/adb/gpm/inject.dex /system/bin ScrollInject --stdio
 * stdin: <x> <y> <dy> [dx] [displayId]
 */
public class ScrollInject {
    private static Method inject;
    private static Object im;

    public static void main(String[] args) throws Exception {
        Class<?> smCls = Class.forName("android.os.ServiceManager");
        IBinder binder = (IBinder) smCls.getMethod("getService", String.class).invoke(null, "input");
        Class<?> stub = Class.forName("android.hardware.input.IInputManager$Stub");
        im = stub.getMethod("asInterface", IBinder.class).invoke(null, binder);
        Class<?> iface = Class.forName("android.hardware.input.IInputManager");
        inject = iface.getMethod("injectInputEvent", android.view.InputEvent.class, int.class);
        System.err.println("injector ready");
        BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
        String line;
        while ((line = r.readLine()) != null) {
            line = line.trim();
            if (line.isEmpty()) continue;
            if (line.equals("q")) break;
            String[] p = line.split("\\s+");
            if (p.length < 3) continue;
            try {
                scroll(Float.parseFloat(p[0]), Float.parseFloat(p[1]), Float.parseFloat(p[2]),
                       p.length > 3 ? Float.parseFloat(p[3]) : 0f,
                       p.length > 4 ? Integer.parseInt(p[4]) : 0);
            } catch (Throwable t) {
                System.err.println("bad line: " + line);
            }
        }
    }

    private static void scroll(float x, float y, float dy, float dx, int displayId) {
        long now = SystemClock.uptimeMillis();
        MotionEvent.PointerProperties props = new MotionEvent.PointerProperties();
        props.id = 0;
        props.toolType = MotionEvent.TOOL_TYPE_MOUSE;
        MotionEvent.PointerCoords coords = new MotionEvent.PointerCoords();
        coords.x = x;
        coords.y = y;
        coords.setAxisValue(MotionEvent.AXIS_VSCROLL, dy);
        coords.setAxisValue(MotionEvent.AXIS_HSCROLL, dx);
        MotionEvent ev = MotionEvent.obtain(now, now, MotionEvent.ACTION_SCROLL, 1,
                new MotionEvent.PointerProperties[]{props},
                new MotionEvent.PointerCoords[]{coords},
                0, 0, 1.0f, 1.0f, 0, 0, InputDevice.SOURCE_MOUSE, 0);
        if (displayId > 0) {
            try { MotionEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId); }
            catch (Throwable ignored) {}
        }
        try { inject.invoke(im, ev, 1); }
        catch (Throwable t) { System.err.println("inject failed: " + t); }
        finally { ev.recycle(); }
    }
}
"""

C_SPAWN = r"""
// ------------------------------------------------------- scroll injector ----
// Spawns the root scroll injector (app_process + IInputManager) once and keeps
// a pipe to its stdin, so the app can ask for real ACTION_SCROLL events.
static int g_inject_fd = -1;

static void spawn_injector(void) {
    const char *dex = "/data/adb/gpm/inject.dex";
    if (access(dex, R_OK) != 0) { out("ERR injector dex missing"); return; }
    int pfd[2];
    if (pipe(pfd) != 0) { out("ERR pipe: %s", strerror(errno)); return; }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(pfd[0], STDIN_FILENO);
        close(pfd[0]);
        close(pfd[1]);
        execl("/system/bin/app_process", "app_process",
              "-Djava.class.path=/data/adb/gpm/inject.dex",
              "/system/bin", "ScrollInject", "--stdio", (char *)NULL);
        _exit(127);
    }
    close(pfd[0]);
    if (pid < 0) { close(pfd[1]); out("ERR fork: %s", strerror(errno)); return; }
    g_inject_fd = pfd[1];
    usleep(1800 * 1000);
    out("INJECTOR %d", (int)pid);
}

static void injector_scroll(float x, float y, float dy, float dx, int disp) {
    if (g_inject_fd < 0) return;
    char buf[128];
    int n = snprintf(buf, sizeof(buf), "%.1f %.1f %.3f %.3f %d\n", x, y, dy, dx, disp);
    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
}

"""

C_CMD = r"""        case 'P': {
            float px, py, pdy, pdx;
            int pdisp = 0;
            int pn = sscanf(line, "%f %f %f %f %d", &px, &py, &pdy, &pdx, &pdisp);
            if (pn >= 3) injector_scroll(px, py, pdy, pdx, pn >= 5 ? pdisp : 0);
            break;
        }
        case 'R': {"""

def main():
    root = r"E:\Dennis\GamePadDex复刻\project"
    with io.open(os.path.join(root, "tools", "injector", "ScrollInject.java"), "w",
                 encoding="utf-8", newline="\n") as f:
        f.write(JAVA)
    print("java written")

    cpath = os.path.join(root, "app", "src", "main", "assets", "gpminput.c")
    with io.open(cpath, "r", encoding="utf-8", newline="") as f:
        c = f.read()

    if "spawn_injector" not in c:
        c = c.replace("#include <sys/stat.h>",
                      "#include <sys/stat.h>\n#include <sys/wait.h>", 1)
        marker = "// ------------------------------------------------------------ gamepads ----"
        assert marker in c, "gamepads marker missing"
        c = c.replace(marker, C_SPAWN + marker, 1)

    if "case 'P':" not in c:
        old = "        case 'R': {"
        assert old in c, "R case missing"
        c = c.replace(old, C_CMD, 1)

    if "spawn_injector();\n        open_devices(0);" not in c:
        old2 = "        open_devices(0);\n        out(\"READY\");"
        assert old2 in c, "startup block missing"
        c = c.replace(old2, "        spawn_injector();\n        open_devices(0);\n        out(\"READY\");", 1)

    with io.open(cpath, "w", encoding="utf-8", newline="") as f:
        f.write(c)
    print("c patched, len=", len(c))

main()
