// gpminput.c  --  Gamepad Mouse (DeX) root helper
//
// Build (WSL):
//   aarch64-linux-gnu-gcc -O2 -static -o gpminput gpminput.c
//
// What it does (needs root):
//   1. Finds every /dev/input/event* device that looks like a gamepad
//      (has BTN_GAMEPAD/BTN_SOUTH + ABS_X), opens it and grabs it with
//      EVIOCGRAB.  While grabbed the whole Android framework (DeX desktop,
//      GameTools, the focused app, ...) receives *nothing* from that device.
//   2. Reads the grabbed devices and prints normalised events on stdout so the
//      Java service can drive the on-screen cursor.
//   3. Creates a virtual mouse and a virtual keyboard through /dev/uinput and
//      injects movement / buttons / wheel / keys on request (stdin commands).
//
// stdout protocol (one line each, '\n' terminated):
//   READY
//   DEV <id> <name>
//   GONE <id>
//   AX <id> <axisCode> <float -1..1>
//   KEY <id> <linuxKeyCode> <0|1>
//   ERR <message>
//
// stdin protocol:
//   M <dx> <dy>            relative mouse movement (floats, sub-pixel kept)
//   B <0|1|2> <0|1>        mouse button left/right/middle
//   S <count>              vertical wheel steps (positive = up)
//   H <count>              horizontal wheel steps
//   K <linuxKeyCode> <0|1> virtual keyboard key
//   R                      release all grabbed devices and grab again
//   Q                      quit
//
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/wait.h>
#include <poll.h>
#include <signal.h>
#include <dirent.h>
#include <sys/inotify.h>
#include <time.h>
#include <math.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include "gpminput.h"

#define MAX_DEVS 8

typedef struct {
    int fd;
    int id;
    int grabbed;
    char name[128];
    char path[64];
    int absmin[ABS_CNT];
    int absmax[ABS_CNT];
    int has_abs[ABS_CNT];
} gpdev_t;

static gpdev_t g_devs[MAX_DEVS];
static int g_ndev = 0;
static int g_mouse = -1;
static int g_kbd = -1;
static int g_pad = -1;
/* 绝对指针设备：只用来「一次性把指针放到指定坐标」（相对鼠标有加速度，算不准） */
static int g_abs_ptr = -1;
/* 居中用的 raw->px 增益（可被命令 G 修改，用于标定） */
static double g_center_gain = 2.16;
/* 最近一次解析到的前台包名（杀应用用） */
static char g_top_pkg[192];
/* 虚拟触摸屏：给"点击=触摸"和"双指缩放"用（真实触摸事件，带多点协议 B） */
static int g_touch_panel = -1;
static int g_touch_w = 1600, g_touch_h = 2560;
static int g_touch_slot0 = -1, g_touch_slot1 = -1;
static int g_pinch_dir = 0;          /* +1 放大 / -1 缩小 / 0 停止 */
static int g_pinch_d = 60;           /* 两指参考距离 */
static int g_pinch_x = 0, g_pinch_y = 0;   /* 缩放基准点（光标位置） */
static long long g_pinch_last_us = 0;
/* forward the physical d-pad to the virtual gamepad (native d-pad for the OS) */
static int g_dpad_native = 0;
static volatile sig_atomic_t g_quit = 0;
static int g_grab_mode = 0;
static int g_listen = -1;

void out(const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf) - 1, fmt, ap);
    va_end(ap);
    if (n < 0) return;
    if (n > (int)sizeof(buf) - 2) n = sizeof(buf) - 2;
    buf[n++] = '\n';
    // write() directly, ignore partial writes for these tiny lines
    ssize_t r = write(STDOUT_FILENO, buf, n);
    /* the client is gone: leave instead of writing into a dead socket,
     * otherwise the session can never hand over to a new connection */
    if (r < 0 && (errno == EPIPE || errno == ECONNRESET)) g_quit = 1;
    static int logfd = -2;
    if (logfd == -2) {
        mkdir("/data/adb", 0755);
        mkdir("/data/adb/gpm", 0755);
        logfd = open("/data/adb/gpm/helper.log", O_WRONLY | O_CREAT | O_APPEND, 0644);
    }
    if (logfd >= 0) {
        ssize_t w = write(logfd, buf, n);
        (void)w;
    }
}

/* heartbeat: the app reconnects when no line arrives for a few seconds */
static void ping_client(void) {
    const char m[] = "PING\n";
    ssize_t r = write(STDOUT_FILENO, m, sizeof(m) - 1);
    (void)r;
}

static void on_signal(int sig) { (void)sig; g_quit = 1; }

/* reap fire-and-forget children (async `input swipe`, `am start`, ...) */
static void reap_children(void) {
    int st;
    while (waitpid(-1, &st, WNOHANG) > 0) {
    }
}

// ---------------------------------------------------------------- uinput ----
static int uinput_open(void) {
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) fd = open("/dev/input/uinput", O_WRONLY | O_NONBLOCK);
    return fd;
}

static int make_mouse(void) {
    int fd = uinput_open();
    if (fd < 0) { out("ERR cannot open /dev/uinput: %s", strerror(errno)); return -1; }
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_REL);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
    ioctl(fd, UI_SET_KEYBIT, BTN_MIDDLE);
    ioctl(fd, UI_SET_RELBIT, REL_X);
    ioctl(fd, UI_SET_RELBIT, REL_Y);
    ioctl(fd, UI_SET_RELBIT, REL_WHEEL);
    ioctl(fd, UI_SET_RELBIT, REL_HWHEEL);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x5678;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Mouse Pointer");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { out("ERR UI_DEV_SETUP(mouse) %s", strerror(errno)); close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { out("ERR UI_DEV_CREATE(mouse) %s", strerror(errno)); close(fd); return -1; }
    return fd;
}

/* 绝对指针（cursor input）：系统把它当鼠标，但坐标是绝对的，
 * 因此「居中」只需一条 EV_ABS，不需要猜像素增益。 */
static int make_abs_pointer(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
    ioctl(fd, UI_SET_KEYBIT, BTN_MIDDLE);
#ifdef UI_SET_PROPBIT
    ioctl(fd, UI_SET_PROPBIT, INPUT_PROP_POINTER);
#endif
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    struct uinput_abs_setup as;
    memset(&as, 0, sizeof(as));
    as.code = ABS_X;
    as.absinfo.minimum = 0;
    as.absinfo.maximum = 32767;
    ioctl(fd, UI_ABS_SETUP, &as);
    memset(&as, 0, sizeof(as));
    as.code = ABS_Y;
    as.absinfo.minimum = 0;
    as.absinfo.maximum = 32767;
    ioctl(fd, UI_ABS_SETUP, &as);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x567a;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Absolute Pointer");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

static void ev_emit(int fd, int type, int code, int val);
static void ev_syn(int fd);

/* 虚拟触摸屏：Android 用多点协议 B（SLOT + TRACKING_ID + POSITION）。
 * INPUT_PROP_DIRECT 让系统把它当真正的触摸板而不是鼠标。 */
static int make_touchscreen(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_TOUCH);
#ifdef UI_SET_PROPBIT
    ioctl(fd, UI_SET_PROPBIT, INPUT_PROP_DIRECT);
#endif
    int axes[] = { ABS_X, ABS_Y, ABS_MT_SLOT, ABS_MT_TRACKING_ID,
                   ABS_MT_POSITION_X, ABS_MT_POSITION_Y };
    for (size_t i = 0; i < sizeof(axes) / sizeof(axes[0]); i++) ioctl(fd, UI_SET_ABSBIT, axes[i]);

    struct uinput_abs_setup as;
    for (size_t i = 0; i < sizeof(axes) / sizeof(axes[0]); i++) {
        memset(&as, 0, sizeof(as));
        as.code = axes[i];
        if (axes[i] == ABS_MT_SLOT) { as.absinfo.minimum = 0; as.absinfo.maximum = 9; }
        else if (axes[i] == ABS_MT_TRACKING_ID) { as.absinfo.minimum = -1; as.absinfo.maximum = 65535; }
        else { as.absinfo.minimum = 0; as.absinfo.maximum = 32767; }
        ioctl(fd, UI_ABS_SETUP, &as);
    }

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x567b;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Touch Panel");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

/* 把一个屏幕像素坐标换算成触摸设备的 0..32767 坐标 */
static int touch_axis(int v, int max) {
    if (max <= 0) max = 1;
    if (v < 0) v = 0;
    if (v > max) v = max;
    return (int)((long long)v * 32767 / max);
}

static void touch_frame(int slot, int tid, int x, int y) {
    if (g_touch_panel < 0) return;
    ev_emit(g_touch_panel, EV_ABS, ABS_MT_SLOT, slot);
    ev_emit(g_touch_panel, EV_ABS, ABS_MT_TRACKING_ID, tid);
    if (tid >= 0) {
        ev_emit(g_touch_panel, EV_ABS, ABS_MT_POSITION_X, touch_axis(x, g_touch_w));
        ev_emit(g_touch_panel, EV_ABS, ABS_MT_POSITION_Y, touch_axis(y, g_touch_h));
    }
    ev_syn(g_touch_panel);
}

/* 单指按下 / 抬起（点击、长按） */
static void touch_single(int x, int y, int down) {
    if (g_touch_panel < 0) { g_touch_panel = make_touchscreen(); usleep(120 * 1000); }
    if (g_touch_panel < 0) { out("ERR touch device"); return; }
    if (down) {
        if (g_touch_slot0 < 0) { g_touch_slot0 = 1; ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1); }
        touch_frame(0, g_touch_slot0, x, y);
        out("TOUCH down %d,%d", x, y);
    } else {
        if (g_touch_slot0 >= 0) {
            touch_frame(0, -1, 0, 0);
            ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 0);
            ev_syn(g_touch_panel);
            g_touch_slot0 = -1;
            out("TOUCH up");
        }
    }
}

/* 双指缩放：由主循环按 8~16ms 节奏推动，按住期间连续生效 */
static void pinch_stop(void) {
    if (g_pinch_dir == 0) return;
    g_pinch_dir = 0;
    if (g_touch_panel >= 0) {
        if (g_touch_slot1 >= 0) touch_frame(1, -1, 0, 0);
        if (g_touch_slot0 >= 0) touch_frame(0, -1, 0, 0);
        ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 0);
        ev_syn(g_touch_panel);
    }
    g_touch_slot0 = g_touch_slot1 = -1;
    out("PINCH stop");
}

static void pinch_start(int dir, int x, int y) {
    if (g_touch_panel < 0) { g_touch_panel = make_touchscreen(); usleep(120 * 1000); }
    if (g_touch_panel < 0) { out("ERR touch device"); return; }
    pinch_stop();
    g_pinch_dir = dir > 0 ? 1 : -1;
    g_pinch_x = x;
    g_pinch_y = y;
    g_pinch_d = 80;
    g_touch_slot0 = 11;
    g_touch_slot1 = 12;
    g_pinch_last_us = 0;
    ev_emit(g_touch_panel, EV_KEY, BTN_TOUCH, 1);
    touch_frame(0, g_touch_slot0, x - g_pinch_d, y);
    touch_frame(1, g_touch_slot1, x + g_pinch_d, y);
    out("PINCH start dir=%d at %d,%d", dir, x, y);
}

static void pinch_tick(void) {
    if (g_pinch_dir == 0 || g_touch_panel < 0) return;
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    long long now = (long long)ts.tv_sec * 1000000 + ts.tv_nsec / 1000;
    if (now - g_pinch_last_us < 14000) return;   /* ~70 fps */
    g_pinch_last_us = now;
    g_pinch_d += g_pinch_dir * 9;
    int limit = g_touch_h / 3;
    if (limit < 120) limit = 120;
    if (g_pinch_d < 24) g_pinch_d = 24;
    if (g_pinch_d > limit) g_pinch_d = limit;
    touch_frame(0, g_touch_slot0, g_pinch_x - g_pinch_d, g_pinch_y);
    touch_frame(1, g_touch_slot1, g_pinch_x + g_pinch_d, g_pinch_y);
}

static int make_keyboard(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    // enable the usual consumer / media / navigation range
    for (int k = 1; k < 256; k++) ioctl(fd, UI_SET_KEYBIT, k);
    for (int k = 0x160; k < 0x2a0; k++) ioctl(fd, UI_SET_KEYBIT, k);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x5679;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Mouse Keyboard");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

static void ev_emit(int fd, int type, int code, int val) {
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type;
    ev.code = code;
    ev.value = val;
    ssize_t r = write(fd, &ev, sizeof(ev));
    (void)r;
}

static void ev_syn(int fd) { ev_emit(fd, EV_SYN, SYN_REPORT, 0); }

/* Virtual gamepad used only to hand the *physical d-pad* back to the system.
 * Android's gamepad mapper turns ABS_HAT0X/Y into KEYCODE_DPAD_* itself, so the
 * system sees a real d-pad (games: native d-pad, apps: native focus keys).
 * BTN_DPAD_* does not work here: this device has no .kl and those codes are
 * unmapped, while HAT axes are handled by the InputReader in code. */
static int make_gamepad(void) {
    int fd = uinput_open();
    if (fd < 0) return -1;
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_A);
    ioctl(fd, UI_SET_KEYBIT, BTN_B);
    ioctl(fd, UI_SET_KEYBIT, BTN_X);
    ioctl(fd, UI_SET_KEYBIT, BTN_Y);
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    ioctl(fd, UI_SET_ABSBIT, ABS_HAT0X);
    ioctl(fd, UI_SET_ABSBIT, ABS_HAT0Y);

    struct uinput_abs_setup as;
    memset(&as, 0, sizeof(as));
    as.code = ABS_X;
    as.absinfo.minimum = -32768;
    as.absinfo.maximum = 32767;
    as.absinfo.fuzz = 16;
    as.absinfo.flat = 128;
    ioctl(fd, UI_ABS_SETUP, &as);
    as.code = ABS_Y;
    ioctl(fd, UI_ABS_SETUP, &as);
    memset(&as, 0, sizeof(as));
    as.code = ABS_HAT0X;
    as.absinfo.minimum = -1;
    as.absinfo.maximum = 1;
    ioctl(fd, UI_ABS_SETUP, &as);
    as.code = ABS_HAT0Y;
    ioctl(fd, UI_ABS_SETUP, &as);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    us.id.vendor = 0x1234;
    us.id.product = 0x567a;
    us.id.version = 1;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Gamepad Mouse Virtual Dpad");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { close(fd); return -1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { close(fd); return -1; }
    return fd;
}

/* keyboard key codes for the virtual keyboard (Generic.kl maps them to
 * KEYCODE_DPAD_*), that is the system's own arrow-key handling */
static void arrow_emit(int key) {
    if (g_kbd < 0) return;
    ev_emit(g_kbd, EV_KEY, key, 1);
    ev_syn(g_kbd);
    ev_emit(g_kbd, EV_KEY, key, 0);
    ev_syn(g_kbd);
    /* tell the app we are in native navigation, so it can translate A into
     * DPAD_CENTER (activate the focused item) instead of a mouse click */
    out("PAD %d", key);
}

static int g_hat_x = 0, g_hat_y = 0;

/* buttons currently held (gamepad buttons, d-pad excluded): while a modifier
 * such as X is held the d-pad must go to the app so that combos (X + arrow)
 * still work; native forwarding is only for the plain d-pad case. */
static int g_held[16];
static int g_held_n = 0;

static int is_dpad_btn(int c) { return c >= BTN_DPAD_UP && c <= BTN_DPAD_RIGHT; }
static void held_add(int c) {
    if (is_dpad_btn(c)) return;
    for (int i = 0; i < g_held_n; i++) if (g_held[i] == c) return;
    if (g_held_n < 16) g_held[g_held_n++] = c;
}
static void held_del(int c) {
    for (int i = 0; i < g_held_n; i++) {
        if (g_held[i] == c) {
            g_held[i] = g_held[--g_held_n];
            return;
        }
    }
}
static int any_btn_held(void) { return g_held_n > 0; }

static void pad_hat(int axis, int value) {
    /* only on edges: pads repeat the same HAT value, which would double-step */
    if (axis == ABS_HAT0X) {
        if (value == g_hat_x) return;
        g_hat_x = value;
    } else if (axis == ABS_HAT0Y) {
        if (value == g_hat_y) return;
        g_hat_y = value;
    } else {
        return;
    }
    if (value == 0) return;
    if (axis == ABS_HAT0X) {
        arrow_emit(value < 0 ? KEY_LEFT : KEY_RIGHT);
    } else {
        arrow_emit(value < 0 ? KEY_UP : KEY_DOWN);
    }
}

static void pad_dpad_key(int code, int value) {
    if (value == 0) return;
    switch (code) {
        case BTN_DPAD_UP: arrow_emit(KEY_UP); break;
        case BTN_DPAD_DOWN: arrow_emit(KEY_DOWN); break;
        case BTN_DPAD_LEFT: arrow_emit(KEY_LEFT); break;
        case BTN_DPAD_RIGHT: arrow_emit(KEY_RIGHT); break;
        default: break;
    }
}


// ------------------------------------------------------- scroll injector ----
// Spawns the root scroll injector (app_process + IInputManager) once and keeps
// a pipe to its stdin, so the app can ask for real ACTION_SCROLL events.
static int g_inject_fd = -1;
static pid_t g_inject_pid = -1;


// Reads the system pointer position from SurfaceFlinger's cursor sprite layer
// (the only source for it on a non-system app) and prints "CURSOR <x> <y>".
static void query_cursor(void) {
    FILE *p = popen("dumpsys SurfaceFlinger 2>/dev/null", "r");
    if (!p) { out("CURSOR -1 -1"); return; }
    char line[512];
    int near_sprite = 0, rows = 0;
    double x = -1, y = -1;
    while (fgets(line, sizeof(line), p)) {
        if (!near_sprite) {
            if (strstr(line, "LayerFE ([BBQ] Sprite")) near_sprite = 1;
            continue;
        }
        double a, b, c2;
        if (sscanf(line, " %lf %lf %lf", &a, &b, &c2) == 3) {
            if (rows == 0) { x = c2; rows = 1; }
            else if (rows == 1) { y = c2; rows = 2; break; }
        }
    }
    pclose(p);
    out("CURSOR %.0f %.0f", x, y);
}


// true when another helper is already listening on this socket (only one helper
// may hold the EVIOCGRAB, otherwise input lands in a helper nobody talks to)

// hard single-instance guard: only one helper may hold the EVIOCGRAB
static int g_lock_fd = -1;
static int take_single_instance_lock(void) {
    /* O_CLOEXEC: spawned helpers (su/uiautomator/input) must not inherit the lock */
    g_lock_fd = open("/data/adb/gpm/helper.lock", O_CREAT | O_RDWR | O_CLOEXEC, 0666);
    if (g_lock_fd < 0) return 1;            /* cannot lock: better run than not */
    if (flock(g_lock_fd, LOCK_EX | LOCK_NB) != 0) return 0;
    return 1;
}

static int socket_alive(const char *path) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return 0;
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);
    int r = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    close(fd);
    return r == 0;
}

static void spawn_injector(void) {
    /* disabled: app_process cannot be used from this domain, so the injector is
       not started at all; clicks use `input tap`, scrolling uses uinput */
    if (1) return;
    if (g_inject_fd >= 0) return;   // already running
    const char *dex = "/data/adb/gpm/inject.dex";
    if (access(dex, R_OK) != 0) { out("ERR injector dex missing"); return; }
    int pfd[2];
    if (pipe(pfd) != 0) { out("ERR pipe: %s", strerror(errno)); return; }
    pid_t pid = fork();
    if (pid == 0) {
        dup2(pfd[0], STDIN_FILENO);
        close(pfd[0]);
        close(pfd[1]);
        /* service.sh starts us with a minimal environment: app_process needs
           ANDROID_ROOT / LD_LIBRARY_PATH or the linker cannot find its libs */
        execl("/system/bin/sh", "sh", "-c",
              "export ANDROID_ROOT=/system; export ANDROID_DATA=/data; "
              "export LD_LIBRARY_PATH=/apex/com.android.art/lib64:/system/lib64:/system_ext/lib64:/product/lib64:/vendor/lib64; "
              "exec /system/bin/app_process -Djava.class.path=/data/adb/gpm/inject.dex "
              "/system/bin ScrollInject --stdio",
              (char *)NULL);
        _exit(127);
    }
    close(pfd[0]);
    if (pid < 0) { close(pfd[1]); out("ERR fork: %s", strerror(errno)); return; }
    g_inject_fd = pfd[1];
    g_inject_pid = pid;
    usleep(1800 * 1000);
    out("INJECTOR %d", (int)pid);
}


// keeps the scroll injector alive: respawns it if the child exits or the pipe
// breaks (the app keeps talking to us, so the injector must not be a single
// point of failure)
static void check_injector(void) {
    if (g_inject_pid > 0) {
        int st = 0;
        pid_t r = waitpid(g_inject_pid, &st, WNOHANG);
        if (r == g_inject_pid) {
            out("INJECTOR died (st=%d), respawning", st);
            if (g_inject_fd >= 0) { close(g_inject_fd); g_inject_fd = -1; }
            g_inject_pid = -1;
            spawn_injector();
        }
    } else if (g_inject_fd < 0) {
        spawn_injector();
    }
}


// Finds the foreground app window on the given display, computes the position of
// the DeX caption "fullscreen" button (2nd from the right) and clicks it through
// the injector.
static void injector_key(int displayId, int androidKeyCode);


// same parse as query_cursor() but returns the numbers
static void cmd_mouse_move(double dx, double dy);

static void query_cursor_pos(int *ox, int *oy) {
    *ox = -1; *oy = -1;
    FILE *p = popen("dumpsys SurfaceFlinger 2>/dev/null", "r");
    if (!p) return;
    char line[512];
    int seen = 0, rows = 0;
    double x = -1, y = -1;
    while (fgets(line, sizeof(line), p)) {
        if (!seen) {
            if (strstr(line, "LayerFE ([BBQ] Sprite")) seen = 1;
            continue;
        }
        double a, b, c;
        if (sscanf(line, " %lf %lf %lf", &a, &b, &c) == 3) {
            if (rows == 0) { x = c; rows = 1; }
            else { y = c; break; }
        }
    }
    pclose(p);
    if (x > 0 && y > 0) { *ox = (int)x; *oy = (int)y; }
}

/* real pointer position: prefer the InputDispatcher hover position (exact),
 * fall back to the SurfaceFlinger cursor sprite. (0,0) is a valid position, so
 * "not found" is tracked separately from the parsed values. */
static void read_pointer(int *ox, int *oy) {
    *ox = -1; *oy = -1;
    int found = 0;
    FILE *p = popen("dumpsys input 2>/dev/null", "r");
    if (p) {
        char buf[1024];
        int mouse_seen = 0;
        while (fgets(buf, sizeof(buf), p)) {
            char *h = strstr(buf, "hoveringPointers=");
            if (!h) continue;
            char *at = strstr(h, "at (");
            if (!at) continue;
            float fx = 0, fy = 0;
            if (sscanf(at + 4, "%f, %f", &fx, &fy) == 2) {
                /* prefer the mouse pointer: other hovering pointers (stylus,
                 * touch) live in different coordinate spaces */
                int is_mouse = strstr(h, "MOUSE") != NULL;
                if (!found || (is_mouse && !mouse_seen)) {
                    *ox = (int)fx;
                    *oy = (int)fy;
                    found = 1;
                    mouse_seen = is_mouse;
                }
                if (mouse_seen) break;
            }
        }
        pclose(p);
    }
    if (!found) query_cursor_pos(ox, oy);
}

static void caption_fullscreen_click(int displayId, int screen_w, int screen_h) {
    /* 1) root: force the foreground task to fill the display (maximized) */
    char tid[16] = {0};
    FILE *p = popen("dumpsys activity activities 2>/dev/null | grep -m1 -oE 'Task\\{[^}]*#[0-9]+ type=standard A=[0-9]+:com\\.example\\.' 2>/dev/null", "r");
    if (!p) p = popen("dumpsys activity activities 2>/dev/null | grep -m1 -oE 'Task\\{[^}]*#[0-9]+' ", "r");
    if (p) {
        char line[512];
        if (fgets(line, sizeof(line), p)) {
            char *h = strrchr(line, '#');
            if (h) {
                int i = 0;
                h++;
                while (*h >= '0' && *h <= '9' && i < 8) tid[i++] = *h++;
                tid[i] = 0;
            }
        }
        pclose(p);
    }
    if (tid[0] && screen_w > 0 && screen_h > 0) {
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "/system/bin/am task resize %s 0 0 %d %d >/dev/null 2>&1", tid, screen_w, screen_h);
        int rc = system(cmd);
        out("FULLSCREEN resize task %s -> %dx%d rc=%d", tid, screen_w, screen_h, rc);
        usleep(600 * 1000);
    }

    /* 2) the caption is now at the top-right of the display: click the
          fullscreen icon, then put the pointer back where it was */
    int before_x = -1, before_y = -1;
    query_cursor_pos(&before_x, &before_y);
    int x = screen_w > 0 ? screen_w - 115 : 2445;
    int y = 30;
    out("CAPTION click %d,%d", x, y);
    {
        char tap[128];
        snprintf(tap, sizeof(tap), "/system/bin/input -d %d tap %d %d >/dev/null 2>&1", displayId, x, y);
        system(tap);
        out("CAPTION tapped %d,%d", x, y);
    }
    if (before_x > 0 && before_y > 0) {
        usleep(200 * 1000);
        cmd_mouse_move((double)(before_x - x), (double)(before_y - y));
        out("CAPTION restored pointer to %d,%d", before_x, before_y);
    }
}

static void injector_combo(int displayId, const char *combo) {
    if (g_inject_fd < 0) { check_injector(); return; }
    char buf[160];
    int n = snprintf(buf, sizeof(buf), "c %d %s\n", displayId, combo);
    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; out("COMBO %d %s", displayId, combo); }
}

static void injector_key(int displayId, int androidKeyCode) {
    if (g_inject_fd < 0) { check_injector(); return; }
    char buf[64];
    int n = snprintf(buf, sizeof(buf), "k %d %d\n", displayId, androidKeyCode);
    if (n > 0) { ssize_t r = write(g_inject_fd, buf, (size_t)n); (void)r; }
}

static void injector_scroll(float x, float y, float dy, float dx, int disp) {
    if (g_inject_fd < 0) { check_injector(); return; }
    char buf[128];
    int n = snprintf(buf, sizeof(buf), "%.1f %.1f %.3f %.3f %d\n", x, y, dy, dx, disp);
    if (n > 0) {
        ssize_t r = write(g_inject_fd, buf, (size_t)n);
        if (r < 0 && (errno == EPIPE || errno == EBADF)) {
            close(g_inject_fd);
            g_inject_fd = -1;
            g_inject_pid = -1;
            spawn_injector();
        }
    }
}

// ------------------------------------------------------------ gamepads ----
static int bit_test(const unsigned long *bits, int n) {
    return (bits[n / (8 * sizeof(long))] >> (n % (8 * sizeof(long)))) & 1UL;
}

static int is_gamepad(int fd) {
    unsigned long evbits[(EV_MAX / (8 * sizeof(long))) + 1];
    unsigned long keybits[(KEY_MAX / (8 * sizeof(long))) + 1];
    unsigned long absbits[(ABS_MAX / (8 * sizeof(long))) + 1];
    memset(evbits, 0, sizeof(evbits));
    memset(keybits, 0, sizeof(keybits));
    memset(absbits, 0, sizeof(absbits));
    if (ioctl(fd, EVIOCGBIT(0, sizeof(evbits)), evbits) < 0) return 0;
    if (!bit_test(evbits, EV_KEY) || !bit_test(evbits, EV_ABS)) return 0;
    if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(keybits)), keybits) < 0) return 0;
    if (ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(absbits)), absbits) < 0) return 0;
    int pad = bit_test(keybits, BTN_GAMEPAD) || bit_test(keybits, BTN_SOUTH) ||
              bit_test(keybits, BTN_JOYSTICK) || bit_test(keybits, BTN_TRIGGER);
    int stick = bit_test(absbits, ABS_X) || bit_test(absbits, ABS_HAT0X);
    // exclude touchscreens / stylus: they have ABS_MT_POSITION_X or BTN_TOOL_FINGER
    if (bit_test(absbits, ABS_MT_POSITION_X)) return 0;
    if (bit_test(keybits, BTN_TOOL_FINGER) || bit_test(keybits, BTN_TOUCH)) return 0;
    return pad && stick;
}

// linux evdev ABS_* -> android MotionEvent AXIS_* (the Java side speaks
// MotionEvent axis ids). Unipolar Z/RZ on xpad-style pads are the triggers.
static int axis_to_android(const gpdev_t *d, int code) {
    // A pad that has ABS_RX/ABS_RY uses Z/RZ as the triggers; a pad without a
    // separate right-stick axis pair keeps the right stick on Z/RZ.
    int has_right_stick = d->has_abs[3] || d->has_abs[4];
    switch (code) {
        case 0:  return 0;   // ABS_X      -> AXIS_X
        case 1:  return 1;   // ABS_Y      -> AXIS_Y
        case 2:  return has_right_stick ? 17 : 11; // Z  -> LTRIGGER / AXIS_Z
        case 3:  return 12;  // ABS_RX     -> AXIS_RX
        case 4:  return 13;  // ABS_RY     -> AXIS_RY
        case 5:  return has_right_stick ? 18 : 14; // RZ -> RTRIGGER / AXIS_RZ
        case 6:  return 19;  // ABS_THROTTLE -> AXIS_THROTTLE
        case 7:  return 20;  // ABS_RUDDER   -> AXIS_RUDDER
        case 8:  return 21;  // ABS_WHEEL    -> AXIS_WHEEL
        case 9:  return 22;  // ABS_GAS    -> AXIS_GAS
        case 10: return 23;  // ABS_BRAKE  -> AXIS_BRAKE
        case 16: return 15;  // ABS_HAT0X  -> AXIS_HAT_X
        case 17: return 16;  // ABS_HAT0Y  -> AXIS_HAT_Y
        default: return code;
    }
}
// close + drop a dead device node, keeping the array compact
static void remove_dev(int idx) {
    if (idx < 0 || idx >= g_ndev) return;
    if (g_devs[idx].grabbed) ioctl(g_devs[idx].fd, EVIOCGRAB, 0);
    out("GONE %d %s", g_devs[idx].id, g_devs[idx].name);
    close(g_devs[idx].fd);
    for (int j = idx; j < g_ndev - 1; j++) g_devs[j] = g_devs[j + 1];
    g_ndev--;
    /* a device that vanished while a key was down would otherwise keep the
     * "some button is held" state forever and disable d-pad forwarding */
    g_held_n = 0;
}
// add gamepads that appeared after startup (hotplug)
static void read_absinfo(gpdev_t *d);

static time_t g_last_wake_at = 0;
static int g_ino_fd = -1;

/* monotonic milliseconds: the app uses System.nanoTime()/1e6 (same clock), so
 * the stamps can be subtracted to get the real input latency */
static long long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000LL + ts.tv_nsec / 1000000LL;
}
static int screen_awake(void) {
    FILE *f = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -m1 mWakefulness=", "r");
    char b[128] = {0};
    int awake = 0;
    if (f) {
        if (fgets(b, sizeof(b), f)) {
            if (strstr(b, "Awake")) awake = 1;
        }
        pclose(f);
    }
    return awake;
}
/* 通用文档 §6: wake the screen when a gamepad is connected (no unlock).
 * The virtual keyboard's KEY_WAKEUP is used first (uinput, SELinux-safe);
 * KEYCODE_WAKEUP via `input` is only a fallback. */
static void wake_key_once(void) {
    /* 1) the virtual keyboard's KEY_WAKEUP (kernel-level, no exec) */
    if (g_kbd >= 0) {
        ev_emit(g_kbd, EV_KEY, 224 /* KEY_WAKEUP */, 1);
        ev_syn(g_kbd);
        usleep(60 * 1000);
        ev_emit(g_kbd, EV_KEY, 224, 0);
        ev_syn(g_kbd);
        usleep(500 * 1000);
        if (screen_awake() == 1) return;
    }
    /* 2) KEYCODE_WAKEUP through `input` (works from the root context) */
    system("/system/bin/input keyevent 224");
    usleep(500 * 1000);
    if (screen_awake() == 1) return;
    /* 3) last resort: PowerManager.wakeUp() via a global-namespace shell */
    system("/system/bin/su -M -c 'cmd power wakeup' </dev/null >/dev/null 2>&1");
    usleep(500 * 1000);
}

/* kill every process whose /proc/<pid>/cmdline starts with the package name
 * (the KSU SELinux domain cannot always use `cmd activity force-stop`) */
static int kill_pkg_procs(const char *pkg) {
    DIR *d = opendir("/proc");
    if (!d) return -1;
    int killed = 0;
    size_t plen = strlen(pkg);
    struct dirent *e;
    while ((e = readdir(d))) {
        if (e->d_name[0] < '0' || e->d_name[0] > '9') continue;
        char path[64], buf[512];
        snprintf(path, sizeof(path), "/proc/%s/cmdline", e->d_name);
        int fd = open(path, O_RDONLY);
        if (fd < 0) continue;
        ssize_t n = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        if (n <= 0) continue;
        buf[n] = 0;
        if (strncmp(buf, pkg, plen) == 0) {
            int pid = atoi(e->d_name);
            if (pid > 1) {
                kill(pid, SIGKILL);
                killed++;
            }
        }
    }
    closedir(d);
    return killed;
}

static void maybe_wake_on_connect(const char *name) {
    time_t now = time(NULL);
    if (now - g_last_wake_at < 3) return;   /* 3 s debounce */
    int st = screen_awake();
    if (st == 1) {
        out("WAKE skip awake %s", name);
        return;
    }
    g_last_wake_at = now;
    wake_key_once();
    usleep(600 * 1000);
    if (screen_awake() != 1) {
        system("/system/bin/su -c \"PATH=/system/bin cmd power wakeup\"");
        usleep(600 * 1000);
    }
    out("WAKE_CONNECT %s (was %d now %d)", name, st, screen_awake());
}

static void scan_new_devices(void) {
    for (int i = 0; i < 64 && g_ndev < MAX_DEVS; i++) {
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/event%d", i);
        int already = 0;
        for (int k = 0; k < g_ndev; k++) {
            if (strcmp(g_devs[k].path, path) == 0) { already = 1; break; }
        }
        if (already) continue;
        int fd = open(path, O_RDWR | O_NONBLOCK);
        if (fd < 0) continue;
        if (!is_gamepad(fd)) { close(fd); continue; }
        gpdev_t *d = &g_devs[g_ndev];
        memset(d, 0, sizeof(*d));
        d->fd = fd;
        d->id = g_ndev;
        snprintf(d->path, sizeof(d->path), "%s", path);
        ioctl(fd, EVIOCGNAME(sizeof(d->name) - 1), d->name);
        if (g_grab_mode) {
            if (ioctl(fd, EVIOCGRAB, 1) < 0) {
                out("ERR grab %s (%s) failed: %s", path, d->name, strerror(errno));
                close(fd);
                continue;
            }
            d->grabbed = 1;
        }
        read_absinfo(d);
        out("DEV %d %s", d->id, d->name);
        if (d->grabbed) out("GRABBED %d %s", d->id, d->name);
        maybe_wake_on_connect(d->name);
        g_ndev++;
    }
}
static void read_absinfo(gpdev_t *d) {
    for (int a = 0; a < ABS_CNT; a++) {
        struct input_absinfo ai;
        if (ioctl(d->fd, EVIOCGABS(a), &ai) == 0) {
            d->absmin[a] = ai.minimum;
            d->absmax[a] = ai.maximum;
            const unsigned long *bits = NULL;
            unsigned long absbits[(ABS_MAX / (8 * sizeof(long))) + 1];
            memset(absbits, 0, sizeof(absbits));
            if (ioctl(d->fd, EVIOCGBIT(EV_ABS, sizeof(absbits)), absbits) >= 0) bits = absbits;
            d->has_abs[a] = bits ? bit_test(bits, a) : (ai.maximum > ai.minimum);
        } else {
            d->has_abs[a] = 0;
        }
    }
}

static void open_devices(int grab) {
    g_ndev = 0;
    for (int i = 0; i < 64 && g_ndev < MAX_DEVS; i++) {
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/event%d", i);
        int fd = open(path, O_RDWR | O_NONBLOCK);
        if (fd < 0) continue;
        if (!is_gamepad(fd)) { close(fd); continue; }
        gpdev_t *d = &g_devs[g_ndev];
        memset(d, 0, sizeof(*d));
        d->fd = fd;
        d->id = g_ndev;
        snprintf(d->path, sizeof(d->path), "%s", path);
        ioctl(fd, EVIOCGNAME(sizeof(d->name) - 1), d->name);
        if (grab) {
            if (ioctl(fd, EVIOCGRAB, 1) < 0) {
                out("ERR grab %s (%s) failed: %s", path, d->name, strerror(errno));
                close(fd);
                continue;
            }
            d->grabbed = 1;
        }
        read_absinfo(d);
        out("DEV %d %s", d->id, d->name);
        if (grab) out("GRABBED %d %s", d->id, d->name);
        g_ndev++;
    }
    if (g_ndev == 0) out("ERR no gamepad found");
}

static void scan_new_devices(void);

static void grab_all(void) {
    g_grab_mode = 1;
    for (int i = 0; i < g_ndev; i++) {
        if (!g_devs[i].grabbed) {
            if (ioctl(g_devs[i].fd, EVIOCGRAB, 1) == 0) {
                g_devs[i].grabbed = 1;
                out("GRABBED %d %s", g_devs[i].id, g_devs[i].name);
            } else {
                out("ERR grab %s failed: %s", g_devs[i].name, strerror(errno));
            }
        }
    }
}

static void ungrab_all(void) {
    g_grab_mode = 0;
    /* the system owns the controller now: stop forwarding the d-pad as well,
     * otherwise the keys would be delivered twice (native + virtual keyboard) */
    g_dpad_native = 0;
    for (int i = 0; i < g_ndev; i++) {
        if (g_devs[i].grabbed) {
            ioctl(g_devs[i].fd, EVIOCGRAB, 0);
            g_devs[i].grabbed = 0;
            out("GONE %d %s", g_devs[i].id, g_devs[i].name);
        }
    }
}

static float normalize_abs(gpdev_t *d, int code, int value) {
    int lo = d->absmin[code], hi = d->absmax[code];
    switch (code) {
        case ABS_HAT0X: case ABS_HAT0Y:
            return (float)value;
        case ABS_GAS: case ABS_BRAKE:
            return (hi > lo) ? (float)(value - lo) / (float)(hi - lo) : 0.0f;
        case ABS_Z: case ABS_RZ:
            /* 有右摇杆的手柄：Z/RZ 是扳机，按 0..1 归一（否则要按到 75% 才触发） */
            if (d->has_abs[ABS_RX] || d->has_abs[ABS_RY]) {
                if (hi <= lo) return 0.0f;
                return (float)(value - lo) / (float)(hi - lo);
            }
            if (hi <= lo) return 0.0f;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;
        case ABS_X: case ABS_Y: case ABS_RX: case ABS_RY:
            if (hi <= lo) return 0.0f;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;
        default:
            if (hi <= lo) return (float)value;
            return 2.0f * ((float)(value - lo) / (float)(hi - lo)) - 1.0f;
    }
}

// ------------------------------------------------------------- commands ----
static double g_mouse_acc_x = 0.0, g_mouse_acc_y = 0.0;

/* 鼠标设备可能被「空闲隐藏」销毁了：任何一次移动/点击前都确保它存在，
 * 否则 App 侧状态一旦不同步，就会表现为「光标不见了/点了没反应」。 */
static void ensure_mouse(void) {
    if (g_mouse >= 0) return;
    g_mouse = make_mouse();
    if (g_mouse >= 0) {
        usleep(120 * 1000);
        out("MOUSE_REOPEN (auto)");
    }
}

static void cmd_mouse_move(double dx, double dy) {
    ensure_mouse();
    if (g_mouse < 0) return;
    g_mouse_acc_x += dx;
    g_mouse_acc_y += dy;
    int ix = (int)g_mouse_acc_x;
    int iy = (int)g_mouse_acc_y;
    g_mouse_acc_x -= ix;
    g_mouse_acc_y -= iy;
    if (ix != 0) ev_emit(g_mouse, EV_REL, REL_X, ix);
    if (iy != 0) ev_emit(g_mouse, EV_REL, REL_Y, iy);
    if (ix != 0 || iy != 0) ev_syn(g_mouse);
}

static void cmd_mouse_button(int btn, int down) {
    ensure_mouse();
    if (g_mouse < 0) return;
    int code = btn == 0 ? BTN_LEFT : btn == 1 ? BTN_RIGHT : BTN_MIDDLE;
    ev_emit(g_mouse, EV_KEY, code, down ? 1 : 0);
    ev_syn(g_mouse);
}

/* pointer movement gain (REL delta -> on-screen pixels) measured at runtime */
static double g_pointer_gain = 3.25;

/* move the pointer in *display* coordinates, accounting for the display
 * rotation (REL events are in natural device space) */
static void move_display(double dx, double dy, int rot) {
    double rx = dx, ry = dy;
    if (rot == 1) {            /* ROTATION_90 */
        rx = dy;
        ry = -dx;
    } else if (rot == 2) {     /* ROTATION_180 */
        rx = -dx;
        ry = -dy;
    } else if (rot == 3) {     /* ROTATION_270 */
        rx = -dy;
        ry = dx;
    }
    cmd_mouse_move(rx, ry);
}

/* move the pointer to the centre of the display: O <maxX> <maxY> [park] [rot] */
/* 居中：先用"多个有界小步"把指针推到左上角（一个 -30000 的大位移会把指针甩出屏幕、
 * 之后连 hover 都没有），再按增益一步走到屏幕中心。
 * 用法：O <w> <h> <park> <rot> [gain] */
static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    double gain = g_center_gain > 0.2 ? g_center_gain : 2.16;
    int tx = maxX / 2, ty = maxY / 2;
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (center)");
    }
    /* 1) 有界步进到左上角：总量约 1.2 屏，分成 40 步，每步很小 */
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    /* 2) 从(0,0)一步到中心 */
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
    out("CENTER(steps+gain %.2f) rot=%d -> %d,%d", gain, rot, tx, ty);
}

static void cmd_wheel(int n, int horizontal) {
    ensure_mouse();
    if (g_mouse < 0) return;
    if (n == 0) return;
    ev_emit(g_mouse, EV_REL, horizontal ? REL_HWHEEL : REL_WHEEL, n);
    ev_syn(g_mouse);
    out("WHEEL %d h=%d", n, horizontal);
}

/* Horizontal scrolling for touch-first apps: REL_HWHEEL is ignored by many
 * apps (PiliPlus etc.), a touch drag is not. The swipe is anchored at the
 * mouse pointer so it lands inside whatever list the user is aiming at.
 * usage: W <display> <dx> <ms> <maxX> <maxY> */
/* readable screen state? (cheap: one grep on dumpsys power) */
static int screen_awake_readable(void) {
    FILE *p = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -c mWakefulness=", "r");
    int ok = 0;
    if (p) {
        char b[32] = {0};
        if (fgets(b, sizeof(b), p)) ok = atoi(b) > 0 ? 1 : 0;
        pclose(p);
    }
    return ok;
}

/* 链路自检 (通用 §8.1): one line per capability */
static void cmd_selftest(void) {
    out("SELFTEST begin");
    out("CAP mouse %d", g_mouse >= 0 ? 1 : 0);
    out("CAP kbd %d", g_kbd >= 0 ? 1 : 0);
    out("CAP wheel %d", (g_mouse >= 0) ? 1 : 0);
    out("CAP swipe %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP notif %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("CAP power %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP force %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
    out("CAP screen %d", screen_awake_readable());
    out("CAP devices %d", g_ndev);
    out("SELFTEST end");
}

/* 读取当前前台包名（topResumedActivity）。
 *
 * `dumpsys activity activities` 要 100~300 ms，如果直接在命令循环里同步跑，
 * 每 2 秒就会卡住输入处理一次（游戏中能感觉到顿）。所以这里改成：
 *   1) 立即返回上一次缓存的结果（/data/adb/gpm/top.txt）
 *   2) 后台 fork 一个子进程去刷新缓存，下一次查询就是新的
 * 前台包名只用于「桌面/系统弹窗」判定，晚 2 秒完全没问题。 */
#define TOP_CACHE "/data/adb/gpm/top.txt"

static void top_cache_read(char *out_pkg, size_t n) {
    out_pkg[0] = 0;
    FILE *f = fopen(TOP_CACHE, "r");
    if (!f) return;
    if (!fgets(out_pkg, (int)n, f)) out_pkg[0] = 0;
    fclose(f);
    char *nl = strchr(out_pkg, '\n');
    if (nl) *nl = 0;
}

static void top_cache_refresh_async(void) {
    pid_t c = fork();
    if (c != 0) return;
    /* 子进程：跑 dumpsys，把包名写进缓存文件 */
    FILE *p = popen("/system/bin/dumpsys activity activities 2>/dev/null | "
                    "/system/bin/grep -m1 topResumedActivity", "r");
    char pkg[192] = {0};
    if (p) {
        char line[512];
        if (fgets(line, sizeof(line), p)) {
            char *u = strstr(line, "u0 ");
            if (u) {
                u += 3;
                size_t i = 0;
                while (u[i] && u[i] != '/' && u[i] != ' ' && i + 1 < sizeof(pkg)) {
                    pkg[i] = u[i];
                    i++;
                }
                pkg[i] = 0;
            }
        }
        pclose(p);
    }
    if (pkg[0]) {
        FILE *f = fopen(TOP_CACHE ".tmp", "w");
        if (f) {
            fprintf(f, "%s\n", pkg);
            fclose(f);
            rename(TOP_CACHE ".tmp", TOP_CACHE);
        }
    }
    _exit(0);
}

static void top_package(char *out_pkg, size_t n) {
    top_cache_read(out_pkg, n);
    /* 缓存为空时同步查一次，保证第一次调用就有值 */
    if (!out_pkg[0]) {
        FILE *p = popen("/system/bin/dumpsys activity activities 2>/dev/null | "
                        "/system/bin/grep -m1 topResumedActivity", "r");
        if (p) {
            char line[512];
            if (fgets(line, sizeof(line), p)) {
                char *u = strstr(line, "u0 ");
                if (u) {
                    u += 3;
                    size_t i = 0;
                    while (u[i] && u[i] != '/' && u[i] != ' ' && i + 1 < n) {
                        out_pkg[i] = u[i];
                        i++;
                    }
                    out_pkg[i] = 0;
                }
            }
            pclose(p);
        }
        if (out_pkg[0]) {
            FILE *f = fopen(TOP_CACHE ".tmp", "w");
            if (f) {
                fprintf(f, "%s\n", out_pkg);
                fclose(f);
                rename(TOP_CACHE ".tmp", TOP_CACHE);
            }
        }
    } else {
        /* 有缓存：让子进程去刷新，主循环立刻返回 */
        top_cache_refresh_async();
    }
}

/* ---------------------------------------------------------------- 滑动用的缓存
 * cmd_swipe 以前每次都同步 popen("dumpsys activity activities") 取前台 task 边界，
 * 一次 100~300 ms，滑动首帧会明显卡一下。现在改成：
 *   - 边界读缓存文件 /data/adb/gpm/taskbounds.txt（子进程后台刷新，最多 2 秒一次）
 *   - 光标位置由 App 随命令一起传过来（App 自己知道估算位置），不再 dumpsys input
 * 这样滑动命令本身就是纯内存计算 + fork 注入，主循环零阻塞。 */
#define BOUNDS_CACHE "/data/adb/gpm/taskbounds.txt"

/* 最近一次已知的光标位置（App 传进来的），用于没有显式传坐标时的回退 */
static int g_ptr_x = -1, g_ptr_y = -1;

static int bounds_cache_read(int *x1, int *y1, int *x2, int *y2) {
    FILE *f = fopen(BOUNDS_CACHE, "r");
    if (!f) return 0;
    int a = 0, b = 0, c = 0, d = 0;
    int ok = fscanf(f, "%d %d %d %d", &a, &b, &c, &d) == 4;
    fclose(f);
    if (!ok || c <= a || d <= b) return 0;
    *x1 = a; *y1 = b; *x2 = c; *y2 = d;
    return 1;
}

static void bounds_cache_refresh_async(int maxX, int maxY) {
    struct stat st;
    if (stat(BOUNDS_CACHE, &st) == 0 && time(NULL) - st.st_mtime < 2) return;
    pid_t c = fork();
    if (c != 0) return;
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY, found = 0;
    if (t) {
        char tl[2048];
        int l0 = 0, t0 = 0, r0 = 0, b0 = 0, have = 0, since = 999;
        while (fgets(tl, sizeof(tl), t)) {
            since++;
            char *mb = strstr(tl, "mBounds=Rect(");
            if (mb) {
                int x1 = 0, y1 = 0, x2 = 0, y2 = 0;
                if (sscanf(mb + strlen("mBounds=Rect("), "%d, %d - %d, %d", &x1, &y1, &x2, &y2) == 4) {
                    l0 = x1; t0 = y1; r0 = x2; b0 = y2;
                    have = 1; since = 0;
                }
            }
            if (strstr(tl, "topResumedActivity=ActivityRecord{")) {
                if (have && since <= 12 && r0 > l0 && b0 > t0 &&
                    r0 <= maxX + 200 && b0 <= maxY + 200) {
                    bx1 = l0; by1 = t0; bx2 = r0; by2 = b0; found = 1;
                }
                break;
            }
        }
        pclose(t);
    }
    if (found) {
        FILE *f = fopen(BOUNDS_CACHE ".tmp", "w");
        if (f) {
            fprintf(f, "%d %d %d %d\n", bx1, by1, bx2, by2);
            fclose(f);
            rename(BOUNDS_CACHE ".tmp", BOUNDS_CACHE);
        }
    } else {
        /* 没解析出来也写个空标记，避免每帧都 fork 重试 */
        FILE *f = fopen(BOUNDS_CACHE ".tmp", "w");
        if (f) { fprintf(f, "0 0 %d %d\n", maxX, maxY); fclose(f); rename(BOUNDS_CACHE ".tmp", BOUNDS_CACHE); }
    }
    _exit(0);
}

static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct,
                      int have_cursor, int cursor_x, int cursor_y) {
    if (delta == 0) return;
    struct timespec t_start, t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    /* foreground task bounds: the swipe must start inside the app, otherwise
     * it lands on the desktop and nothing scrolls. The bounds of the focused
     * task appear just above its topResumedActivity line; taking the first
     * mBounds in the dump would return the root task (full display) and let
     * the pointer anchor land on the desktop. */
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    if (!bounds_cache_read(&bx1, &by1, &bx2, &by2)) {
        bx1 = 0; by1 = 0; bx2 = maxX; by2 = maxY;
    }
    /* 后台刷新边界（2 秒节流），本次用缓存/全屏兜底，绝不同步 dumpsys */
    bounds_cache_refresh_async(maxX, maxY);

    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;
    /* 光标位置：优先用命令里带的坐标（App 传的），其次用上次已知值；
     * 都不行就落在 task 中心。不再调用 dumpsys input。 */
    int cx = -1, cy = -1;
    if (have_cursor) { cx = cursor_x; cy = cursor_y; g_ptr_x = cursor_x; g_ptr_y = cursor_y; }
    else if (g_ptr_x >= 0 && g_ptr_y >= 0) { cx = g_ptr_x; cy = g_ptr_y; }
    if (cx > bx1 + 10 && cx < bx2 - 10 && cy > by1 + 10 && cy < by2 - 10) {
        x = cx;
        y = cy;
    }
    /* startPct >= 0 forces the start on the moving axis (percent of the task
     * size): pull-down/drawer gestures need to start near the top edge, while
     * plain scrolling is fine from the pointer or the task centre. */
    if (startPct >= 0) {
        if (vertical) {
            y = by1 + (by2 - by1) * startPct / 100;
        } else {
            x = bx1 + (bx2 - bx1) * startPct / 100;
        }
    }
    if (x < bx1 + 20) x = bx1 + 20;
    if (x > bx2 - 20) x = bx2 - 20;
    if (y < by1 + 20) y = by1 + 20;
    if (y > by2 - 20) y = by2 - 20;

    int x2 = x;
    int y2 = y;
    if (vertical) {
        y2 = y + delta;
        if (y2 < by1 + 20) y2 = by1 + 20;
        if (y2 > by2 - 20) y2 = by2 - 20;
    } else {
        x2 = x + delta;
        if (x2 < bx1 + 20) x2 = bx1 + 20;
        if (x2 > bx2 - 20) x2 = bx2 - 20;
    }
    /* 手势保护区：从顶部 12% 往下的滑动会被系统/桌面当成「拉通知栏」，
     * 所以向下的滑动必须从保护区以下起手（这是桌面下滑拉出状态栏的根因）。 */
    if (vertical && delta > 0) {
        int guard = by1 + (by2 - by1) * 12 / 100;
        if (y < guard) { y = guard; y2 = guard + delta; }
        if (y2 > by2 - 20) y2 = by2 - 20;
    }
    if (ms <= 0) ms = 480;
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "input -d %d swipe %d %d %d %d %d", display, x, y, x2, y2, ms);
    /* async: `input swipe` takes ~300 ms and would stall the helper's command
     * loop (queued pointer moves => visible stutter while paging) */
    pid_t child = fork();
    if (child == 0) {
        int rc = system(cmd);
        out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) rc=%d", display, x, y, x2, y2,
            bx1, bx2, by1, by2, rc);
        _exit(0);
    }
    clock_gettime(CLOCK_MONOTONIC, &t_end);
    long long prep_us = (long long)(t_end.tv_sec - t_start.tv_sec) * 1000000 +
                        (t_end.tv_nsec - t_start.tv_nsec) / 1000;
    out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) async prep=%lldus", display, x, y, x2, y2,
        bx1, bx2, by1, by2, prep_us);
}

/* root task ids that belong to one display (from `am stack list`) */
static int collect_display_roots(int display, int *ids, int maxn) {
    int n = 0;
    FILE *p = popen("am stack list 2>/dev/null", "r");
    if (!p) return 0;
    char buf[1024];
    while (fgets(buf, sizeof(buf), p) && n < maxn) {
        char *rt = strstr(buf, "RootTask id=");
        if (!rt) continue;
        char *dd = strstr(buf, "displayId=");
        if (!dd) continue;
        int id = atoi(rt + strlen("RootTask id="));
        int d = atoi(dd + strlen("displayId="));
        if (d == display) ids[n++] = id;
    }
    pclose(p);
    return n;
}

typedef struct {
    char comp[128];
    int root;
} recent_entry_t;

static int on_display_root(const int *roots, int nr, int root) {
    for (int i = 0; i < nr; i++)
        if (roots[i] == root) return 1;
    return 0;
}

/* recents (newest first) that live on this display */
static int collect_display_recents(int display, recent_entry_t *out, int maxn) {
    int roots[16];
    int nr = collect_display_roots(display, roots, 16);
    int n = 0;
    FILE *p = popen("dumpsys activity recents 2>/dev/null", "r");
    if (!p) return 0;
    char buf[2048];
    char comp[128] = {0};
    int root = -1;
    int started = 0;
#define FINALIZE()                                                                   \
    do {                                                                             \
        if (started && comp[0] && root >= 0 && on_display_root(roots, nr, root) &&   \
            strstr(comp, "com.sec.android.app.launcher") == NULL &&                  \
            strstr(comp, "com.android.systemui") == NULL && n < maxn) {              \
            snprintf(out[n].comp, sizeof(out[n].comp), "%s", comp);                  \
            out[n].root = root;                                                      \
            n++;                                                                     \
        }                                                                            \
    } while (0)
    while (fgets(buf, sizeof(buf), p)) {
        if (strstr(buf, "* Recent #")) {
            FINALIZE();
            comp[0] = 0;
            root = -1;
            started = 1;
            continue;
        }
        if (!started) continue;
        char *c = strstr(buf, "mActivityComponent=");
        if (c) {
            sscanf(c + strlen("mActivityComponent="), "%127s", comp);
            continue;
        }
        char *rr = strstr(buf, "rootTaskId=");
        if (rr) root = atoi(rr + strlen("rootTaskId="));
    }
    FINALIZE();
#undef FINALIZE
    pclose(p);
    return n;
}

/* Switch to another app that lives on this display only: Alt+Tab injection is
 * ignored by DeX, so pick the most recent app from `dumpsys activity recents`
 * whose root task is on this display (phone-only apps are skipped) and bring
 * its task to the front with `am start`.
 * usage: Y <display> */


/* force the phone orientation: 0 portrait, 1 landscape, -1 back to automatic */
static void cmd_rotation(int rot) {
    char cmd[256];
    if (rot < 0) {
        system("settings put system accelerometer_rotation 1");
        system("wm set-ignore-orientation-request false");
    } else {
        snprintf(cmd, sizeof(cmd),
                 "settings put system accelerometer_rotation 0; "
                 "settings put system user_rotation %d", rot);
        system(cmd);
        /* portrait-only apps must obey too */
        system("wm set-ignore-orientation-request true");
    }
    out("ROTATION %d", rot);
}

/* close the currently focused app on the phone: L
 * (DeX closes the window with ALT+F4, the phone has no such shortcut, so this
 * force-stops the foreground package instead) */
static void cmd_close_app(void) {
    char comp[160] = {0};
    FILE *p = popen("dumpsys activity activities 2>/dev/null", "r");
    if (p) {
        char buf[2048];
        while (fgets(buf, sizeof(buf), p)) {
            char *t = strstr(buf, "topResumedActivity=ActivityRecord{");
            if (!t) continue;
            char *u0 = strstr(t, " u0 ");
            if (!u0) continue;
            sscanf(u0 + 4, "%159s", comp);
            break;
        }
        pclose(p);
    }
    char pkg[160] = {0};
    snprintf(pkg, sizeof(pkg), "%s", comp);
    char *slash = strchr(pkg, '/');
    if (slash) *slash = 0;
    if (pkg[0] == 0) {
        out("CLOSE_APP no focused app");
        return;
    }
    if (strstr(pkg, "com.dennis.dexpad") || strstr(pkg, "launcher") ||
        strstr(pkg, "systemui") || strstr(pkg, "sec.android.app.launcher")) {
        out("CLOSE_APP skip %s", pkg);
        return;
    }
    /* 真正杀：am force-stop + 直接 SIGKILL 兜底（保证"确实死了"） */
    {
        int n = kill_pkg_procs(pkg);
        out("CLOSE_APP sigkill %s n=%d", pkg, n);
    }
    char cmd[320];
    snprintf(cmd, sizeof(cmd), "am force-stop %s", pkg);
    pid_t child = fork();
    if (child == 0) {
        int rc = system(cmd);
        out("CLOSE_APP %s rc=%d", pkg, rc);
        _exit(0);
    }
    out("CLOSE_APP %s async", pkg);
}

static void cmd_switch_app(int display) {
    /* current focused component (may be the launcher) */
    char cur[128] = {0};
    FILE *p = popen("dumpsys activity activities 2>/dev/null", "r");
    if (p) {
        char buf[2048];
        while (fgets(buf, sizeof(buf), p)) {
            char *t = strstr(buf, "topResumedActivity=ActivityRecord{");
            if (!t) continue;
            char *u0 = strstr(t, " u0 ");
            if (!u0) continue;
            sscanf(u0 + 4, "%127s", cur);
            break;
        }
        pclose(p);
    }

    recent_entry_t apps[12];
    int n = collect_display_recents(display, apps, 12);
    if (n == 0) {
        out("SWITCH no DeX app on display %d", display);
        return;
    }
    int target = -1;
    /* compare by *package*: one app can have several activity components
     * (Settings has dozens), and matching components would "switch" to another
     * activity of the same app — which looks like nothing happened. */
    char cur_pkg[128] = {0};
    snprintf(cur_pkg, sizeof(cur_pkg), "%s", cur);
    char *slash = strchr(cur_pkg, '/');
    if (slash) *slash = '\0';
    for (int i = 0; i < n; i++) {
        char pkg[128] = {0};
        snprintf(pkg, sizeof(pkg), "%s", apps[i].comp);
        char *s = strchr(pkg, '/');
        if (s) *s = '\0';
        if (cur_pkg[0] && strcmp(pkg, cur_pkg) == 0) continue;
        target = i;
        break;
    }
    if (target < 0) {
        out("SWITCH no other app than %s", cur);
        return;
    }
    char cmd[320];
    snprintf(cmd, sizeof(cmd), "am start -n '%s' --display %d >/dev/null 2>&1", apps[target].comp, display);
    int rc = system(cmd);
    out("SWITCH %s -> %s rc=%d", cur, apps[target].comp, rc);
}


static void cmd_key(int code, int down) {
    if (g_kbd < 0) return;
    ev_emit(g_kbd, EV_KEY, code, down ? 1 : 0);
    ev_syn(g_kbd);
}

/* Android keycode -> Linux input code（只覆盖映射表里会用到的组合键） */
static int android_to_linux(int a) {
    switch (a) {
        case 113: return 29;   /* CTRL_LEFT */
        case 114: return 97;   /* CTRL_RIGHT */
        case 57:  return 56;   /* ALT_LEFT */
        case 58:  return 100;  /* ALT_RIGHT */
        case 59:  return 42;   /* SHIFT_LEFT */
        case 60:  return 54;   /* SHIFT_RIGHT */
        case 61:  return 15;   /* TAB */
        case 131: return 59;   /* F1 */
        case 132: return 60;   /* F2 */
        case 133: return 61;   /* F3 */
        case 134: return 62;   /* F4 */
        case 69:  return 12;   /* MINUS */
        case 81:  return 13;   /* PLUS */
        case 67:  return 14;   /* DEL */
        case 29:  return 30;   /* A */
        case 30:  return 48;   /* B */
        case 31:  return 46;   /* C */
        case 32:  return 32;   /* D */
        case 33:  return 18;   /* E */
        case 122: return 172;  /* HOME -> KEY_HOMEPAGE */
        case 4:   return 158;  /* BACK */
        case 187: return 125;  /* APP_SWITCH */
        case 3:   return 172;  /* HOME -> KEY_HOMEPAGE */
        case 24:  return 115;  /* VOLUME_UP */
        case 25:  return 114;  /* VOLUME_DOWN */
        case 164: return 113;  /* MUTE */
        case 85:  return 164;  /* MEDIA_PLAY_PAUSE */
        case 87:  return 163;  /* MEDIA_NEXT */
        case 88:  return 165;  /* MEDIA_PREVIOUS */
        /* 常用字符 / 功能键（自定义快捷键用） */
        case 62:  return 57;   /* SPACE */
        case 66:  return 28;   /* ENTER */
        case 160: return 28;   /* NUMPAD_ENTER */
        case 111: return 1;    /* ESCAPE */
        case 112: return 111;  /* FORWARD_DEL */
        case 19:  return 103;  /* DPAD_UP */
        case 20:  return 108;  /* DPAD_DOWN */
        case 21:  return 105;  /* DPAD_LEFT */
        case 22:  return 106;  /* DPAD_RIGHT */
        case 123: return 107;  /* MOVE_END */
        case 120: return 99;   /* SYSRQ (截图) */
        case 23:  return 352;  /* DPAD_CENTER -> KEY_OK */
        case 82:  return 139;  /* MENU */
        case 92:  return 104;  /* PAGE_UP */
        case 93:  return 109;  /* PAGE_DOWN */
        case 117: return 125;  /* META_LEFT (win) */
        case 118: return 126;  /* META_RIGHT */
        case 7:   return 2;    /* 0 */
        case 8:   return 3;    /* 1 */
        case 9:   return 4;    /* 2 */
        case 10:  return 5;    /* 3 */
        case 11:  return 6;    /* 4 */
        case 12:  return 7;    /* 5 */
        case 13:  return 8;    /* 6 */
        case 14:  return 9;    /* 7 */
        case 15:  return 10;   /* 8 */
        case 16:  return 11;   /* 9 */
        case 34:  return 33;   /* F */
        case 35:  return 34;   /* G */
        case 36:  return 35;   /* H */
        case 37:  return 23;   /* I */
        case 38:  return 36;   /* J */
        case 39:  return 37;   /* K */
        case 40:  return 38;   /* L */
        case 41:  return 50;   /* M */
        case 42:  return 49;   /* N */
        case 43:  return 24;   /* O */
        case 44:  return 25;   /* P */
        case 45:  return 16;   /* Q */
        case 46:  return 19;   /* R */
        case 47:  return 31;   /* S */
        case 48:  return 20;   /* T */
        case 49:  return 22;   /* U */
        case 50:  return 47;   /* V */
        case 51:  return 17;   /* W */
        case 52:  return 45;   /* X */
        case 53:  return 21;   /* Y */
        case 54:  return 44;   /* Z */
        case 135: return 63;   /* F5 */
        case 136: return 64;   /* F6 */
        case 137: return 65;   /* F7 */
        case 138: return 66;   /* F8 */
        case 139: return 67;   /* F9 */
        case 140: return 68;   /* F10 */
        case 141: return 87;   /* F11 */
        case 142: return 88;   /* F12 */
        default:  return -1;
    }
}

/* 依次按下，再逆序释放：Ctrl+Minus 这类组合才会被应用当成“按住组合” */
static int cmd_key_combo(const int *androidCodes, int count) {
    if (g_kbd < 0) return 0;
    int lcode[8];
    int n = 0;
    for (int i = 0; i < count && i < 8; i++) {
        int l = android_to_linux(androidCodes[i]);
        if (l >= 0) lcode[n++] = l;
    }
    if (n == 0) return 0;
    for (int i = 0; i < n; i++) {
        ev_emit(g_kbd, EV_KEY, lcode[i], 1);
        ev_syn(g_kbd);
        usleep(8 * 1000);
    }
    usleep(30 * 1000);
    for (int i = n - 1; i >= 0; i--) {
        ev_emit(g_kbd, EV_KEY, lcode[i], 0);
        ev_syn(g_kbd);
        usleep(8 * 1000);
    }
    return n;
}

/* Alt+Tab via the virtual keyboard: keep ALT held while TAB is pressed, then
 * release both — this is what the DeX app switcher expects (a bare
 * `input keycombination` Alt+Tab is often swallowed). */
static void cmd_alttab(void) {
    if (g_kbd < 0) return;
    ev_emit(g_kbd, EV_KEY, 56, 1);   /* KEY_LEFTALT */
    ev_syn(g_kbd);
    usleep(90 * 1000);
    ev_emit(g_kbd, EV_KEY, 15, 1);   /* KEY_TAB */
    ev_syn(g_kbd);
    usleep(90 * 1000);
    ev_emit(g_kbd, EV_KEY, 15, 0);
    ev_syn(g_kbd);
    usleep(60 * 1000);
    ev_emit(g_kbd, EV_KEY, 56, 0);
    ev_syn(g_kbd);
    out("ALTTAB sent");
}

static void handle_line(char *line) {
    while (*line == ' ' || *line == '\t') line++;
    if (*line == '\0') return;
    char cmd = *line++;
    while (*line == ' ') line++;
    switch (cmd) {
        case 'M': {
            double dx, dy;
            if (sscanf(line, "%lf %lf", &dx, &dy) == 2) cmd_mouse_move(dx, dy);
            break;
        }
        case 'B': {
            int b, v;
            if (sscanf(line, "%d %d", &b, &v) == 2) cmd_mouse_button(b, v);
            break;
        }
        case 'S': {
            int n;
            if (sscanf(line, "%d", &n) == 1) cmd_wheel(n, 0);
            break;
        }
        case 'H': {
            int n;
            if (sscanf(line, "%d", &n) == 1) cmd_wheel(n, 1);
            break;
        }
        case 'V': {
            int disp, dx, ms, mx, my;
            int pct = -1, cx = -1, cy = -1;
            int n = sscanf(line, "%d %d %d %d %d %d %d %d", &disp, &dx, &ms, &mx, &my, &pct, &cx, &cy);
            if (n >= 5) cmd_swipe(disp, dx, ms, mx, my, 0, pct, n >= 8, cx, cy);
            break;
        }
        case 'Z': {
            int disp, dy, ms, mx, my;
            int pct = -1, cx = -1, cy = -1;
            int n = sscanf(line, "%d %d %d %d %d %d %d %d", &disp, &dy, &ms, &mx, &my, &pct, &cx, &cy);
            if (n >= 5) cmd_swipe(disp, dy, ms, mx, my, 1, pct, n >= 8, cx, cy);
            break;
        }
        case 'O': {
            int w, h, park = 0, rot = 0;
            double gain = 0;
            int n = sscanf(line, "%d %d %d %d %lf", &w, &h, &park, &rot, &gain);
            if (n >= 5 && gain > 0.5 && gain < 20.0) g_center_gain = gain;
            if (n >= 2) cmd_center(w, h, park, rot);
            break;
        }
        case 'T': {
            cmd_alttab();
            break;
        }
        case 'Y': {
            int disp = 0;
            if (sscanf(line, "%d", &disp) == 1) {
                /* runs `dumpsys` + `am start`: keep the command loop free */
                if (fork() == 0) {
                    cmd_switch_app(disp);
                    _exit(0);
                }
            }
            break;
        }
        case 'K': {
            int c, v;
            if (sscanf(line, "%d %d", &c, &v) == 2) cmd_key(c, v);
            break;
        }
        case 'G':
            out("GRAB_REQ ndev=%d grabmode=%d", g_ndev, g_grab_mode);
            scan_new_devices();
            out("GRAB_AFTER_SCAN ndev=%d", g_ndev);
            grab_all();
            break;
        case 'U':
            ungrab_all();
            break;
        case 'f': {
            /* 杀前台：包名依次尝试 dumpsys activity / dumpsys window / 缓存，
             * 然后 am force-stop（functional）+ 直接 SIGKILL 所有进程（兜底） */
            char pkg[192] = {0};
            const char *pipes[2] = {
                "/system/bin/dumpsys activity activities 2>/dev/null | /system/bin/grep -m1 topResumedActivity | /system/bin/sed 's/.*u0 \\([^ ]*\\)\\/.*/\\1/'",
                "/system/bin/dumpsys window 2>/dev/null | /system/bin/grep -m1 mCurrentFocus | /system/bin/sed 's/.*u0 \\([^ /]*\\)\\/.*/\\1/'"
            };
            for (int i = 0; i < 2 && !pkg[0]; i++) {
                FILE *fp = popen(pipes[i], "r");
                if (!fp) continue;
                if (fgets(pkg, sizeof(pkg), fp)) {
                    char *nl = strchr(pkg, '\n');
                    if (nl) *nl = 0;
                }
                pclose(fp);
                if (pkg[0] == '\0') pkg[0] = 0;
            }
            if (!pkg[0] && g_top_pkg[0]) {
                snprintf(pkg, sizeof(pkg), "%s", g_top_pkg);
            }
            if (pkg[0]) {
                char cmd[360];
                snprintf(cmd, sizeof(cmd), "/system/bin/am force-stop %s >/dev/null 2>&1", pkg);
                int rc = system(cmd);
                int n = kill_pkg_procs(pkg);
                out("FORCE_STOP %s rc=%d killed=%d", pkg, rc, n);
            } else {
                out("FORCE_STOP none (no foreground package detected)");
            }
            break;
        }
        case '?':
            cmd_selftest();
            break;
        case 'p': {
            /* 模拟电源键：优先用我们自己虚拟键盘的 KEY_POWER（内核级，不依赖
             * SELinux/binder），失败再退回 `input keyevent 26`。 */
            int ok = 0;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, 116 /* KEY_POWER */, 1);
                ev_syn(g_kbd);
                usleep(40 * 1000);
                ev_emit(g_kbd, EV_KEY, 116, 0);
                ev_syn(g_kbd);
                ok = 1;
            }
            if (!ok) {
                /* 兜底放到子进程里跑：`input` 在这个域里可能长时间不返回，
                 * 它会卡住整个命令循环（表现为按键全部失灵）。 */
                if (fork() == 0) {
                    system("/system/bin/input keyevent 26");
                    _exit(0);
                }
            }
            out("POWER uinput=%d", ok);
            break;
        }
        case 'r': {
            int rot = 0;
            if (sscanf(line, "%d", &rot) == 1) cmd_rotation(rot);
            break;
        }
        case 'I': {
            int v = 0;
            if (sscanf(line, "%d", &v) == 1) {
                g_dpad_native = v ? 1 : 0;
                out("DPAD_NATIVE %d", g_dpad_native);
            }
            break;
        }
        case 'L':
            cmd_close_app();
            break;
        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) {
                /* 优先用我们自己的虚拟键盘注入（内核级，稳定）：
                 * `input keyevent` 在 ksu 域里返回 512（exit code 2），事件根本进不去，
                 * HOME/BACK/音量/静音/媒体键全都是"日志有、实际没反应"。 */
                int lc = android_to_linux(kc);
                if (g_kbd >= 0 && lc >= 0) {
                    ev_emit(g_kbd, EV_KEY, lc, 1);
                    ev_syn(g_kbd);
                    usleep(8 * 1000);
                    ev_emit(g_kbd, EV_KEY, lc, 0);
                    ev_syn(g_kbd);
                    out("KEYUIN %d %d lcode=%d", kd, kc, lc);
                } else {
                    /* 没映射的键才退回 input（子进程里跑，避免卡主循环） */
                    if (fork() == 0) {
                        char cmd[160];
                        snprintf(cmd, sizeof(cmd), "/system/bin/input -d %d keyevent %d", kd, kc);
                        int rc = system(cmd);
                        out("KEYON %d %d rc=%d (unmapped)", kd, kc, rc);
                        _exit(0);
                    }
                }
            }
            break;
        }
        case 'C': {
            /* C <display> <androidKeyCode> ... : 组合键（Ctrl+Plus 等）。
             * 不走 `input keycombination`：在 root 上下文里它返回 512（
             * 需要更宽的注入权限），而 uinput 键盘是进程内操作，稳定可用。 */
            char *p = line;
            char *end = NULL;
            int cd = (int)strtol(p, &end, 10);
            if (end == p || cd < 0) { out("ERR C display"); break; }
            p = end;
            int codes[8];
            int count = 0;
            while (*p && count < 8) {
                while (*p == ' ' || *p == '\t') p++;
                if (!*p) break;
                char *e2 = NULL;
                long c = strtol(p, &e2, 10);
                if (e2 == p) break;
                codes[count++] = (int)c;
                p = e2;
            }
            if (count > 0) {
                int n = cmd_key_combo(codes, count);
                out("KCOMBO %d %d emitted=%d", cd, count, n);
            } else {
                out("ERR C no keys");
            }
            break;
        }
        case 't': {
            /* 当前前台包名：桌面/游戏要用 d-pad 转发，而不是触摸滑动 */
            char pkg[160];
            top_package(pkg, sizeof(pkg));
            out("TOP %s", pkg);
            break;
        }
        case 'h': {
            /* 隐藏系统鼠标指针：销毁虚拟鼠标设备（指针图标随之消失） */
            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }
            break;
        }
        case 'j': {
            /* 重新创建虚拟鼠标（指针重新出现） */
            ensure_mouse();
            out("POINTER on");
            break;
        }
        case 'A': {
            /* A <dir> [hold]  dir: 1上 2下 3左 4右
             * 由 App 决策后回写方向：走虚拟键盘的箭头键（与旧的原生转发等价，
             * 系统会把它当成 DPAD_*），没有虚拟键盘时退回 `input keyevent`。 */
            int dir = 0, hold = 0;
            if (sscanf(line, "%d %d", &dir, &hold) < 1) { out("ERR A"); break; }
            int key = (dir == 1) ? 103 : (dir == 2) ? 108 : (dir == 3) ? 105 : 106;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, key, 1);
                ev_syn(g_kbd);
                if (hold) {
                    out("ARROW %d hold", dir);
                    break;
                }
                usleep(45 * 1000);
                ev_emit(g_kbd, EV_KEY, key, 0);
                ev_syn(g_kbd);
                out("ARROW %d", dir);
                break;
            }
            if (hold) {
                /* 没有虚拟键盘：按住语义用 keyevent 实现不了，退化成一次点击 */
            }
            int kc = (dir == 1) ? 19 : (dir == 2) ? 20 : (dir == 3) ? 21 : 22;
            if (fork() == 0) {
                char c2[96];
                snprintf(c2, sizeof(c2), "/system/bin/input keyevent %d", kc);
                system(c2);
                _exit(0);
            }
            out("ARROW %d fallback=key", dir);
            break;
        }
        case 'N': {
            /* cmd statusbar 在这个 SELinux 域里注入不了（rc=512），
             * 改走虚拟键盘的 KEY_NOTIFICATION_CENTER(444) → 系统映射成通知栏。 */
            int ok = 0;
            if (g_kbd >= 0) {
                ev_emit(g_kbd, EV_KEY, 444, 1);
                ev_syn(g_kbd);
                usleep(40 * 1000);
                ev_emit(g_kbd, EV_KEY, 444, 0);
                ev_syn(g_kbd);
                ok = 1;
            }
            out("NOTIF uinput=%d", ok);
            break;
        }
        case 'W':
            query_cursor();
            break;
        case 'J': {
            int jd = 0, jw = 0, jh = 0;
            int n = sscanf(line, "%d %d %d", &jd, &jw, &jh);
            if (n >= 1 && jd > 0) caption_fullscreen_click(jd, n >= 2 ? jw : 0, n >= 3 ? jh : 0);
            break;
        }
        case 'F': {
            int fd = 0;
            char fcomp[192];
            if (sscanf(line, "%d %191s", &fd, fcomp) == 2 && fd > 0) {
                char cmd[420];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d --windowingMode 1 -n %s >/dev/null 2>&1",
                    fd, fcomp);
                int rc = system(cmd);
                out("FULLSCREEN %d %s rc=%d", fd, fcomp, rc);
            }
            break;
        }
        case 'X': {
            int xd = 0;
            char xc[96];
            if (sscanf(line, "%d %95s", &xd, xc) == 2) injector_combo(xd, xc);
            break;
        }
        case 'E': {
            int hd = 0;
            if (sscanf(line, "%d", &hd) == 1 && hd > 0) {
                char cmd[320];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1",
                    hd);
                int rc = system(cmd);
                out("HOMEDEX %d rc=%d", hd, rc);
            }
            break;
        }
        case 'w': {
            /* w <pkg> : 启动目标应用（后台服务自己 startActivity 会被系统拦，
             * 走 root 的 am start 才可靠） */
            char pkg3[192] = {0};
            if (sscanf(line, "%191s", pkg3) == 1 && pkg3[0]) {
                char cmd4[400];
                snprintf(cmd4, sizeof(cmd4),
                         "/system/bin/am start -a android.intent.action.MAIN "
                         "-c android.intent.category.LAUNCHER -p %s >/dev/null 2>&1", pkg3);
                pid_t ch = fork();
                if (ch == 0) {
                    int rc = system(cmd4);
                    out("OPEN_APP %s rc=%d", pkg3, rc);
                    _exit(0);
                }
                out("OPEN_APP %s async", pkg3);
            }
            break;
        }
        case 'q': {
            /* q <w> <h> : 触摸面尺寸（像素 -> 触摸坐标） */
            int tw = 0, th = 0;
            if (sscanf(line, "%d %d", &tw, &th) == 2 && tw > 0 && th > 0) {
                g_touch_w = tw;
                g_touch_h = th;
                out("TOUCH_SIZE %d %d", g_touch_w, g_touch_h);
            }
            break;
        }
        case 'k': {
            /* k <x> <y> <down> : 单指触摸（点击 / 长按） */
            int tx = 0, ty = 0, dn = 0;
            if (sscanf(line, "%d %d %d", &tx, &ty, &dn) == 3) touch_single(tx, ty, dn);
            break;
        }
        case 'l': {
            /* l <dir> <x> <y> : 双指缩放，dir 0=停止 1=放大 -1=缩小 */
            int dir = 0, px = 0, py = 0;
            if (sscanf(line, "%d %d %d", &dir, &px, &py) == 3) {
                if (dir == 0) pinch_stop();
                else pinch_start(dir, px, py);
            }
            break;
        }
        case 'g': {
            /* 标定：设置居中增益（raw -> px） */
            double g = 0;
            if (sscanf(line, "%lf", &g) == 1 && g > 0.2 && g < 20.0) {
                g_center_gain = g;
                out("GAIN %.2f", g_center_gain);
            }
            break;
        }
        case 'P': {
            float px, py, pdy, pdx;
            int pdisp = 0;
            int pn = sscanf(line, "%f %f %f %f %d", &px, &py, &pdy, &pdx, &pdisp);
            if (pn >= 3) injector_scroll(px, py, pdy, pdx, pn >= 5 ? pdisp : 0);
            break;
        }
        case 'R': {
            int was = 0;
            for (int i = 0; i < g_ndev; i++) if (g_devs[i].grabbed) was = 1;
            ungrab_all();
            for (int i = 0; i < g_ndev; i++) close(g_devs[i].fd);
            g_ndev = 0;
            usleep(150 * 1000);
            open_devices(was);
            break;
        }
        case 'Q':
            g_quit = 1;
            break;
        default:
            break;
    }
}

// ------------------------------------------------------------- socket mode ----
static void setup_socket(const char *path) {
    int sfd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (sfd < 0) { out("ERR socket: %s", strerror(errno)); exit(1); }
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s", path);
    if (socket_alive(path)) {
        fprintf(stderr, "another helper already listens on %s - exiting\n", path);
        exit(0);   /* single instance: never fight over the EVIOCGRAB */
    }
    unlink(path);
    if (bind(sfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        fprintf(stderr, "bind %s: %s\n", path, strerror(errno));
        exit(1);
    }
    chmod(path, 0666);
    if (listen(sfd, 1) < 0) { fprintf(stderr, "listen: %s\n", strerror(errno)); exit(1); }
    g_listen = sfd;
    fprintf(stderr, "listening on %s\n", path);
}
int main(int argc, char **argv) {
    signal(SIGTERM, on_signal);
    signal(SIGINT, on_signal);
    signal(SIGPIPE, SIG_IGN);
    /* run at the highest regular priority: the helper sits between the
     * gamepad HID events and the uinput mouse, so wake-up latency shows up
     * directly as input lag */
    setpriority(PRIO_PROCESS, 0, -20);

    if (argc >= 3 && strcmp(argv[1], "--socket") == 0) {
        if (!take_single_instance_lock()) {
            fprintf(stderr, "another helper holds the lock - exiting\n");
            return 0;
        }
        setup_socket(argv[2]);
    }

    g_mouse = make_mouse();
    g_kbd = make_keyboard();
    g_pad = make_gamepad();
    if (g_mouse >= 0 || g_kbd >= 0) usleep(150 * 1000);
    g_ino_fd = inotify_init1(IN_NONBLOCK);
    if (g_ino_fd >= 0) {
        inotify_add_watch(g_ino_fd, "/dev/input", IN_CREATE | IN_ATTRIB | IN_MOVED_TO);
    }

    char linebuf[256];
    /* one session per connected client; the daemon outlives app restarts */
    while (!g_quit) {
        if (g_listen >= 0) {
            int c = accept(g_listen, NULL, NULL);
            if (c < 0) {
                if (errno == EINTR) {
                    if (g_quit) break;
                    continue;
                }
                break;
            }
            dup2(c, STDIN_FILENO);
            dup2(c, STDOUT_FILENO);
            close(c);
            /* the client channel must not leak into spawned shells */
            fcntl(STDIN_FILENO, F_SETFD, FD_CLOEXEC);
        }
        spawn_injector();
        /* grab from the very first open: the app's "block stock input" default is
           on, and a grab later on only succeeds if nobody else took the device */
        g_grab_mode = 1;
        open_devices(1);
        out("READY");
    size_t linelen = 0;
    struct pollfd pfd[1 + MAX_DEVS + 2];
    unsigned char rdbuf[MAX_DEVS][128];

    time_t last_scan = time(NULL);
    while (!g_quit) {
        if (time(NULL) - last_scan >= 2) {
            last_scan = time(NULL);
            check_injector();
            scan_new_devices();
            ping_client();
        }
        int n = 0;
        pfd[n].fd = STDIN_FILENO; pfd[n].events = POLLIN; n++;
        for (int i = 0; i < g_ndev; i++) {
            pfd[n].fd = g_devs[i].fd;
            pfd[n].events = POLLIN;
            n++;
        }
        int ino_idx = -1;
        if (g_ino_fd >= 0) {
            ino_idx = n;
            pfd[n].fd = g_ino_fd;
            pfd[n].events = POLLIN;
            n++;
        }
        int rc = poll(pfd, n, g_pinch_dir != 0 ? 8 : 400);
        reap_children();
        pinch_tick();
        if (rc < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (rc == 0) { pinch_tick(); continue; }

        if (ino_idx >= 0 && (pfd[ino_idx].revents & POLLIN)) {
            char ib[512];
            while (read(g_ino_fd, ib, sizeof(ib)) > 0) { }
            scan_new_devices();
        }

        if (pfd[0].revents & (POLLIN | POLLHUP)) {
            char tmp[512];
            ssize_t rd = read(STDIN_FILENO, tmp, sizeof(tmp));
            if (rd <= 0) break;
            for (ssize_t i = 0; i < rd; i++) {
                char c = tmp[i];
                if (c == '\n' || c == '\r') {
                    linebuf[linelen] = '\0';
                    handle_line(linebuf);
                    linelen = 0;
                } else if (linelen < sizeof(linebuf) - 1) {
                    linebuf[linelen++] = c;
                }
            }
        }

        for (int i = 0; i < g_ndev; i++) {
            if (pfd[1 + i].revents & (POLLHUP | POLLERR | POLLNVAL)) {
                out("GONE_EVT %s revents=%d", g_devs[i].path, pfd[1 + i].revents);
                remove_dev(i);
                i--;
                continue;
            }
            if (!(pfd[1 + i].revents & POLLIN)) continue;
            ssize_t rd = read(g_devs[i].fd, rdbuf[i], sizeof(rdbuf[i]));
            if (rd < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) continue;
                out("GONE_READ %s errno=%d (%s)", g_devs[i].path, errno, strerror(errno));
                remove_dev(i);
                i--;
                continue;
            }
            if (rd == 0) {
                out("GONE_EOF %s", g_devs[i].path);
                remove_dev(i);
                i--;
                continue;
            }
            ssize_t count = rd / (ssize_t)sizeof(struct input_event);
            for (ssize_t k = 0; k < count; k++) {
                struct input_event *ev = (struct input_event *)(rdbuf[i] + k * sizeof(struct input_event));
                if (ev->type == EV_ABS) {
                    /* mouse mode off: the system owns the axes; report nothing */
                    if (!g_grab_mode) continue;
                    /* d-pad 一律上报给 App（软件在虚拟控制器层之上）：
                     * App 决定这是组合键还是普通方向键，再由 H 命令回写到虚拟手柄 */
                    if (ev->code == 3 || ev->code == 4 || ev->code == 2 || ev->code == 5) {
                        if (0) out("AXMAP raw=%d android=%d rx=%d ry=%d name=%s",
                            ev->code, axis_to_android(&g_devs[i], ev->code),
                            g_devs[i].has_abs[3] ? 1 : 0, g_devs[i].has_abs[4] ? 1 : 0,
                            g_devs[i].name);
                    }
                    out("AX %d %d %.4f", g_devs[i].id, axis_to_android(&g_devs[i], ev->code),
                        normalize_abs(&g_devs[i], ev->code, ev->value));
                } else if (ev->type == EV_KEY) {
                    if (ev->value) held_add(ev->code); else held_del(ev->code);
                    /* d-pad 键同样交给 App 处理 */
                    out("KEY %d %d %d %lld", g_devs[i].id, ev->code, ev->value, now_ms());
                }
            }
        }
    }

        ungrab_all();
        for (int i = 0; i < g_ndev; i++) close(g_devs[i].fd);
        g_ndev = 0;
        if (g_listen < 0) break;   /* stdio mode: single session */
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            close(devnull);
        }
    }

    if (g_listen >= 0) close(g_listen);
    if (g_mouse >= 0) { ioctl(g_mouse, UI_DEV_DESTROY); close(g_mouse); }
    if (g_kbd >= 0) { ioctl(g_kbd, UI_DEV_DESTROY); close(g_kbd); }
    return 0;
}


