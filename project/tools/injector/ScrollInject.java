import android.os.IBinder;
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
            if (line.startsWith("m ")) {
                // m <displayId> <x> <y> [button]
                String[] mp = line.split("\\s+");
                if (mp.length >= 4) click(Integer.parseInt(mp[1]), Float.parseFloat(mp[2]),
                        Float.parseFloat(mp[3]), mp.length > 4 ? Integer.parseInt(mp[4]) : 1);
                continue;
            }
            if (line.startsWith("c ")) {
                // c <displayId> <combo>
                String[] cp = line.split("\\s+", 3);
                if (cp.length >= 3) keyCombo(Integer.parseInt(cp[1]), cp[2]);
                continue;
            }
            if (line.startsWith("k ")) {
                // k <displayId> <androidKeyCode>
                String[] kp = line.split("\\s+");
                if (kp.length >= 3) keyEvent(Integer.parseInt(kp[1]), Integer.parseInt(kp[2]));
                continue;
            }
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


    private static int keyCodeOf(String name) {
        return android.view.KeyEvent.keyCodeFromString("KEYCODE_" + name.toUpperCase());
    }

    /** ctrl+alt+f style combo, injected on one display */
    /** mouse click at (x,y) on a display */
    private static void click(int displayId, float x, float y, int button) {
        long now = SystemClock.uptimeMillis();
        for (int action : new int[]{MotionEvent.ACTION_DOWN, MotionEvent.ACTION_UP}) {
            MotionEvent.PointerProperties props = new MotionEvent.PointerProperties();
            props.id = 0;
            props.toolType = MotionEvent.TOOL_TYPE_MOUSE;
            MotionEvent.PointerCoords coords = new MotionEvent.PointerCoords();
            coords.x = x;
            coords.y = y;
            MotionEvent ev = MotionEvent.obtain(now, now, action, 1,
                    new MotionEvent.PointerProperties[]{props},
                    new MotionEvent.PointerCoords[]{coords},
                    button, 0, 1.0f, 1.0f, 0, 0, InputDevice.SOURCE_MOUSE, 0);
            try {
                MotionEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
            } catch (Throwable ignored) {}
            try {
                inject.invoke(im, ev, 1);
                System.err.println("click " + x + "," + y + " disp=" + displayId + " action=" + action);
            } catch (Throwable t) {
                System.err.println("click inject failed: " + t);
            } finally {
                ev.recycle();
            }
        }
    }

    private static void keyCombo(int displayId, String combo) {
        String[] parts = combo.toLowerCase().split("\\+");
        int meta = 0;
        int main = -1;
        for (String p : parts) {
            p = p.trim();
            if (p.isEmpty()) continue;
            if (p.equals("ctrl") || p.equals("control")) meta |= android.view.KeyEvent.META_CTRL_ON;
            else if (p.equals("alt")) meta |= android.view.KeyEvent.META_ALT_ON;
            else if (p.equals("shift")) meta |= android.view.KeyEvent.META_SHIFT_ON;
            else if (p.equals("meta") || p.equals("win") || p.equals("super")) meta |= android.view.KeyEvent.META_META_ON;
            else main = keyCodeOf(p);
        }
        if (main < 0) { System.err.println("bad combo " + combo); return; }
        int[] mods = new int[0];
        java.util.ArrayList<Integer> m = new java.util.ArrayList<>();
        if ((meta & android.view.KeyEvent.META_CTRL_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_CTRL_LEFT);
        if ((meta & android.view.KeyEvent.META_ALT_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_ALT_LEFT);
        if ((meta & android.view.KeyEvent.META_SHIFT_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_SHIFT_LEFT);
        if ((meta & android.view.KeyEvent.META_META_ON) != 0) m.add(android.view.KeyEvent.KEYCODE_META_LEFT);
        long now = SystemClock.uptimeMillis();
        for (int code : m) sendKey(displayId, code, android.view.KeyEvent.ACTION_DOWN, 0, now);
        if (meta != 0) {
            sendKey(displayId, main, android.view.KeyEvent.ACTION_DOWN, meta, now);
            sendKey(displayId, main, android.view.KeyEvent.ACTION_UP, meta, now);
        } else {
            sendKey(displayId, main, android.view.KeyEvent.ACTION_DOWN, 0, now);
            sendKey(displayId, main, android.view.KeyEvent.ACTION_UP, 0, now);
        }
        for (int i = m.size() - 1; i >= 0; i--) sendKey(displayId, m.get(i), android.view.KeyEvent.ACTION_UP, 0, now);
        System.err.println("combo " + combo + " dispatched on " + displayId);
    }

    private static void sendKey(int displayId, int keyCode, int action, int meta, long now) {
        android.view.KeyEvent ev = new android.view.KeyEvent(now, now, action, keyCode, 0, meta);
        try {
            android.view.KeyEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
        } catch (Throwable ignored) {}
        try {
            inject.invoke(im, ev, 1);
        } catch (Throwable t) {
            System.err.println("key inject failed: " + t);
        }
    }

    private static void keyEvent(int displayId, int keyCode) {
        long now = SystemClock.uptimeMillis();
        for (int action : new int[]{android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.ACTION_UP}) {
            android.view.KeyEvent ev = new android.view.KeyEvent(now, now, action, keyCode, 0);
            try {
                android.view.KeyEvent.class.getMethod("setDisplayId", int.class).invoke(ev, displayId);
            } catch (Throwable ignored) {}
            try {
                inject.invoke(im, ev, 1);
                System.err.println("key " + keyCode + " disp=" + displayId + " action=" + action);
            } catch (Throwable t) {
                System.err.println("key inject failed: " + t);
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
