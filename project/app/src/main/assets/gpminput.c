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
//   V/Z <disp> <d> <ms> <maxX> <maxY> <pct> <cx> <cy>   serialized touch swipe
//   N                      notification shade (real pull-down gesture, queued)
//   O <w> <h> [park] [rot] [gain]     centre the pointer (async)
//   P <x> <y> <maxX> <maxY>           put the pointer at absolute coords (async)
//   g [center] [ptr]       query/set raw->px gain (`g` alone prints GAIN ...)
//   u                      wake the screen (no-op when already awake)
//   c                      query the real pointer position (async, CURSOR x y)
//   w <pkg>                launch an app (resolve-activity + am start -n)
//   R                      release all grabbed devices and grab again
//   Q                      quit
//
// Swipe serialization (v1.66): at most one `input swipe` is in flight.
// A swipe of another axis while one is in flight (or within 90ms after it) is
// dropped with `SWIPE_DROP`; same-axis requests queue (depth 2) and run in
// order. Every injection logs `SWIPE ... async prep=<us>` and `SWIPE_DONE`.
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
/* 缁濆鎸囬拡璁惧锛氬彧鐢ㄦ潵銆屼竴娆℃€ф妸鎸囬拡鏀惧埌鎸囧畾鍧愭爣銆嶏紙鐩稿榧犳爣鏈夊姞閫熷害锛岀畻涓嶅噯锛?*/
static int g_abs_ptr = -1;
/* 灞呬腑/缁濆瀹氫綅鐢ㄧ殑 raw->px 澧炵泭锛堝彲琚懡浠?g / O 淇敼锛岀敤浜庢爣瀹氾級銆? * 0 = 鏈爣瀹氾紝鍥炶惤鍒颁笅闈㈠疄娴嬪嚭鏉ョ殑 g_pointer_gain銆?*/
static double g_center_gain = 0.0;
/* 鏈€杩戜竴娆″凡鐭ョ殑灞忓箷灏哄锛堥€氱煡鏍忎笅婊戞墜鍔胯鐢級 */
static int g_disp_w = 0, g_disp_h = 0;
/* 鏈€杩戜竴娆¤В鏋愬埌鐨勫墠鍙板寘鍚嶏紙鏉€搴旂敤鐢級 */
static char g_top_pkg[192];
/* 铏氭嫙瑙︽懜灞忥細缁?鐐瑰嚮=瑙︽懜"鍜?鍙屾寚缂╂斁"鐢紙鐪熷疄瑙︽懜浜嬩欢锛屽甫澶氱偣鍗忚 B锛?*/
static int g_touch_panel = -1;
static int g_touch_w = 1600, g_touch_h = 2560;
static int g_touch_slot0 = -1, g_touch_slot1 = -1;
static int g_pinch_dir = 0;          /* +1 鏀惧ぇ / -1 缂╁皬 / 0 鍋滄 */
static int g_pinch_d = 60;           /* 涓ゆ寚鍙傝€冭窛绂?*/
static int g_pinch_x = 0, g_pinch_y = 0;   /* 缂╂斁鍩哄噯鐐癸紙鍏夋爣浣嶇疆锛?*/
static long long g_pinch_last_us = 0;
/* forward the physical d-pad to the virtual gamepad (native d-pad for the OS) */
static int g_dpad_native = 0;
static volatile sig_atomic_t g_quit = 0;
static int g_grab_mode = 0;
static int g_listen = -1;

/* helper.log fd: shared by the daemon and its short-lived children (background
 * refreshers log there too, never on the client socket). O_CLOEXEC so spawned
 * `input`/`am`/`monkey` processes do not inherit it. */
static int g_logfd = -2;

static int log_fd(void) {
    if (g_logfd == -2) {
        mkdir("/data/adb", 0755);
        mkdir("/data/adb/gpm", 0755);
        g_logfd = open("/data/adb/gpm/helper.log",
                       O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0644);
    }
    return g_logfd;
}

/* append one line to helper.log only (no socket write): used by background
 * refresher children that must not inject lines into the client protocol */
static void logonly(const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf) - 1, fmt, ap);
    va_end(ap);
    if (n < 0) return;
    if (n > (int)sizeof(buf) - 2) n = sizeof(buf) - 2;
    buf[n++] = '\n';
    int fd = log_fd();
    if (fd >= 0) {
        ssize_t w = write(fd, buf, n);
        (void)w;
    }
}

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
    int fd = log_fd();
    if (fd >= 0) {
        ssize_t w = write(fd, buf, n);
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
static void gesture_reap(pid_t pid, int st);
static int gesture_busy(void);
static int gesture_queued(void);
static long long now_ms(void);

static void reap_children(void) {
    int st;
    pid_t p;
    while ((p = waitpid(-1, &st, WNOHANG)) > 0) {
        gesture_reap(p, st);      /* may be our serialized swipe injection */
    }
}

/* child stdio -> /dev/null: background work must never write on the client
 * socket (it would corrupt the line protocol) nor read the command stream */
static int devnull_redirect(void) {
    int fd = open("/dev/null", O_RDWR);
    if (fd < 0) return -1;
    dup2(fd, STDIN_FILENO);
    dup2(fd, STDOUT_FILENO);
    dup2(fd, STDERR_FILENO);
    if (fd > 2) close(fd);
    return 0;
}

/* fork + exec an absolute binary without a shell: one process less than
 * fork+system(), so an injected gesture starts sooner. */
static pid_t spawn_exec(const char *path, char *const argv[]) {
    pid_t pid = fork();
    if (pid != 0) return pid;
    devnull_redirect();
    execv(path, argv);
    _exit(127);
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

/* 缁濆鎸囬拡锛坈ursor input锛夛細绯荤粺鎶婂畠褰撻紶鏍囷紝浣嗗潗鏍囨槸缁濆鐨勶紝
 * 鍥犳銆屽眳涓€嶅彧闇€涓€鏉?EV_ABS锛屼笉闇€瑕佺寽鍍忕礌澧炵泭銆?*/
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

/* ------------------------------------------------ 闈為樆濉炴寜閿噴鏀捐皟搴? * 鏃т唬鐮佸湪鍛戒护寰幆閲?usleep(8~45ms) 鎵嶅彂閲婃斁浜嬩欢锛歞-pad 姣忔鐐规寜閮戒細鎶婃暣涓? * 鍛戒护寰幆锛堟寚閽堢Щ鍔ㄣ€佹父鎴忔墜鏌勮鍙栵級鍗′綇 45ms銆傜幇鍦ㄦ寜涓嬬珛鍗冲啓 uinput锛? * 閲婃斁鏃堕棿鐧昏鍒拌繖閲岋紝鐢变富寰幆鍦ㄥ埌鏈熸椂琛ュ彂鈥斺€斿惊鐜湰浣撲笉鍐?sleep銆?*/
#define MAX_PEND_KEYS 8
typedef struct {
    int fd;
    int code;
    long long due_ms;
} pend_key_t;
static pend_key_t g_pend[MAX_PEND_KEYS];
static int g_npend = 0;

static void key_down(int fd, int code) {
    ev_emit(fd, EV_KEY, code, 1);
    ev_syn(fd);
}
static void key_up(int fd, int code) {
    ev_emit(fd, EV_KEY, code, 0);
    ev_syn(fd);
}
/* schedule a release; if the same fd+code is already pending, keep the earlier
 * deadline (never extend a press by accident) */
static void key_release_later(int fd, int code, int delay_ms) {
    long long due = now_ms() + (delay_ms > 0 ? delay_ms : 1);
    for (int i = 0; i < g_npend; i++) {
        if (g_pend[i].fd == fd && g_pend[i].code == code) {
            if (due < g_pend[i].due_ms) g_pend[i].due_ms = due;
            return;
        }
    }
    if (g_npend < MAX_PEND_KEYS) {
        g_pend[g_npend].fd = fd;
        g_pend[g_npend].code = code;
        g_pend[g_npend].due_ms = due;
        g_npend++;
        return;
    }
    key_up(fd, code);           /* table full: never leave a key stuck down */
}
/* release everything that is due; returns ms until the next pending release
 * (-1 when nothing is pending) so poll() can wake up in time */
static long long key_release_due(void) {
    long long now = now_ms();
    for (int i = 0; i < g_npend; i++) {
        if (now >= g_pend[i].due_ms) {
            key_up(g_pend[i].fd, g_pend[i].code);
            g_pend[i] = g_pend[--g_npend];
            i--;
        }
    }
    long long next = -1;
    for (int i = 0; i < g_npend; i++) {
        long long d = g_pend[i].due_ms - now;
        if (d < 0) d = 0;
        if (next < 0 || d < next) next = d;
    }
    return next;
}
static void key_release_all(void) {
    while (g_npend > 0) {
        g_pend[g_npend - 1].due_ms = 0;
        key_release_due();
    }
}

/* 铏氭嫙瑙︽懜灞忥細Android 鐢ㄥ鐐瑰崗璁?B锛圫LOT + TRACKING_ID + POSITION锛夈€? * INPUT_PROP_DIRECT 璁╃郴缁熸妸瀹冨綋鐪熸鐨勮Е鎽告澘鑰屼笉鏄紶鏍囥€?*/
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

/* 鎶婁竴涓睆骞曞儚绱犲潗鏍囨崲绠楁垚瑙︽懜璁惧鐨?0..32767 鍧愭爣 */
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

/* 鍗曟寚鎸変笅 / 鎶捣锛堢偣鍑汇€侀暱鎸夛級 */
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

/* 鍙屾寚缂╂斁锛氱敱涓诲惊鐜寜 8~16ms 鑺傚鎺ㄥ姩锛屾寜浣忔湡闂磋繛缁敓鏁?*/
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
// Always executed from a child process: `dumpsys SurfaceFlinger` takes
// 200~600ms and must never stall the command loop.
static void query_cursor(void) {
    long long t0 = now_ms();
    FILE *p = popen("dumpsys SurfaceFlinger 2>/dev/null", "r");
    if (!p) { out("CURSOR -1 -1 took=%lldus src=sf", now_ms() - t0); return; }
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
    out("CURSOR %.0f %.0f took=%lldus src=sf", x, y, now_ms() - t0);
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
/* ---------------------------------------------------------- 灞忓箷鐘舵€?/ 鍞ら啋
 * `dumpsys power` 鍗曟 30~80ms锛岀粷涓嶈兘鍦ㄥ懡浠ゅ惊鐜噷鍚屾璺戙€傛墍浠ワ細
 *   - 缂撳瓨鏂囦欢 /data/adb/gpm/wake.txt 鍐欏叆 "Awake <monotonic_ms>"
 *   - 涓诲惊鐜瘡 ~5s 璁╁瓙杩涚▼鍒锋柊涓€娆★紱`u`锛堝強鏃х殑璁惧杩炴帴鍞ら啋锛夎缂撳瓨鍒ゅ畾
 *   - 缂撳瓨杩囨湡(>8s)/缂哄け鏃舵寜鈥滀笉纭畾鈥濆鐞嗭細姝ゆ椂娉ㄥ叆 KEY_WAKEUP 鏄畨鍏ㄧ殑
 *     锛堝睆骞曞凡浜椂 PowerManager.wakeUp() 鏄┖鎿嶄綔锛屼笉浼氭妸灞忓箷鐏帀锛? * 鍛戒护 `u` 璇箟锛氬彧鍦?mWakefulness != Awake 鏃舵敞鍏ワ紱宸蹭寒鏃?*闆舵敞鍏?*骞跺洖鏃ュ織銆? */
#define WAKE_CACHE "/data/adb/gpm/wake.txt"
static long long g_last_wake_req_ms = 0;
static long long g_last_wake_refresh_ms = 0;

/* child stdio: stdin/stderr -> /dev/null, stdout stays on the client socket so
 * a slow-path child can still answer the protocol */
static void child_quiet_stdio(void) {
    int fd = open("/dev/null", O_RDWR);
    if (fd < 0) return;
    dup2(fd, STDIN_FILENO);
    dup2(fd, STDERR_FILENO);
    if (fd > 2) close(fd);
}

static void wake_cache_write(const char *state) {
    FILE *f = fopen(WAKE_CACHE ".tmp", "w");
    if (!f) return;
    fprintf(f, "%s %lld\n", state, now_ms());
    fclose(f);
    rename(WAKE_CACHE ".tmp", WAKE_CACHE);
}

/* 1 = awake, 0 = not awake, -1 = unknown; state/age_ms optional */
static int wake_cached(long long *age_ms, char *state, size_t n) {
    if (age_ms) *age_ms = -1;
    if (state && n) state[0] = 0;
    FILE *f = fopen(WAKE_CACHE, "r");
    if (!f) return -1;
    char st[32] = {0};
    long long ts = 0;
    int got = fscanf(f, "%31s %lld", st, &ts) == 2;
    fclose(f);
    if (!got) return -1;
    if (state && n) snprintf(state, n, "%s", st);
    long long age = now_ms() - ts;
    if (age_ms) *age_ms = age;
    if (age < 0 || age > 8000) return -1;
    return strcmp(st, "Awake") == 0 ? 1 : 0;
}

/* blocking mWakefulness read 鈥?only ever called from a child process */
static int wakefulness_probe(char *state, size_t n) {
    if (state && n) snprintf(state, n, "unknown");
    FILE *p = popen("/system/bin/dumpsys power 2>/dev/null | /system/bin/grep -m1 mWakefulness=", "r");
    if (!p) return -1;
    char b[128] = {0};
    int r = -1;
    if (fgets(b, sizeof(b), p)) {
        char *v = strchr(b, '=');
        if (v) {
            v++;
            while (*v == ' ') v++;
            size_t i = 0;
            while (v[i] && v[i] != '\n' && v[i] != '\r' && i + 1 < n) {
                if (state) state[i] = v[i];
                i++;
            }
            if (state) state[i] = 0;
            r = (state && strcmp(state, "Awake") == 0) ? 1 : 0;
        }
    }
    pclose(p);
    return r;
}

/* keep the wakefulness cache warm without ever blocking the command loop.
 * 姣?4s 涓€娆★細缂撳瓨鍙敤鏉ュ垽鏂€滄槸鍚﹀彲鑳介渶瑕佸敜閱掆€濓紝鐪熸鐨勪笉纭畾鍦烘櫙锛堣
 * cmd_wake_screen锛変細鍏堟帰娴嬪啀娉ㄥ叆锛屾墍浠?4s 鐨勭矑搴﹁冻澶熴€?*/
static void wake_refresh_async(void) {
    long long now = now_ms();
    if (now - g_last_wake_refresh_ms < 4000) return;
    g_last_wake_refresh_ms = now;
    pid_t c = fork();
    if (c != 0) return;
    devnull_redirect();
    char prev[32] = {0};
    long long prev_age = -1;
    wake_cached(&prev_age, prev, sizeof(prev));
    char probe[32] = {0};
    if (wakefulness_probe(probe, sizeof(probe)) >= 0) {
        if (prev[0] && strcmp(prev, probe) != 0)
            logonly("WAKE_STATE %s -> %s", prev, probe);
        wake_cache_write(probe);
    }
    _exit(0);
}

/* Linux KEY_WAKEUP = 143. (224 is KEY_BRIGHTNESSDOWN on Linux 鈥?the old
 * wake_key_once() emitted 224 and therefore pressed brightness-down, which is
 * why the "uinput wake" never worked reliably.) */
static int wake_inject_uinput(void) {
    if (g_kbd < 0) return 0;
    key_down(g_kbd, 143);
    key_release_later(g_kbd, 143, 60);
    return 1;
}

/* blocking KEY_WAKEUP pulse 鈥?only used inside a child process */
static int wake_pulse_uinput(void) {
    if (g_kbd < 0) return 0;
    ev_emit(g_kbd, EV_KEY, 143, 1);
    ev_syn(g_kbd);
    usleep(60 * 1000);
    ev_emit(g_kbd, EV_KEY, 143, 0);
    ev_syn(g_kbd);
    return 1;
}

/* 鎱㈤摼璺細蹇呰鏃跺厛鎺㈡祴锛堢紦瀛樿鈥滀寒鐫€鈥濅絾鍙兘鍒氱伃灞忥級锛屽啀 KEY_WAKEUP 鈫?鍏滃簳銆? * 姘歌繙鍦ㄥ瓙杩涚▼閲岃窇銆俥mitted=1 琛ㄧず鐖惰繘绋嬪凡缁忓彂杩?uinput KEY_WAKEUP銆?*/
static void wake_slow_path(const char *was, int emitted) {
    pid_t c = fork();
    if (c != 0) return;
    child_quiet_stdio();
    long long t0 = now_ms();
    char probe[32] = {0};
    int r = -1;
    int did_probe = emitted ? 0 : 1;
    const char *src = emitted ? "uinput" : "none";
    if (!emitted) {
        /* 鎺㈡祴浼樺厛锛氬睆骞曠湡鐨勪寒鐫€灏变粈涔堥兘涓嶅仛锛堣礋渚嬶級锛屽垰鐏睆鍒欑珛鍒昏ˉ鍙?*/
        r = wakefulness_probe(probe, sizeof(probe));
        if (r >= 0) wake_cache_write(probe);
        if (r == 1) {
            out("WAKE was=%s now=%s uinput=0 skip=1 probe=1", was, probe);
            _exit(0);
        }
        emitted = wake_pulse_uinput();
        src = emitted ? "uinput" : "input224";
        usleep(400 * 1000);
    } else {
        usleep(400 * 1000);
    }
    r = wakefulness_probe(probe, sizeof(probe));
    if (r >= 0) wake_cache_write(probe);
    if (r != 1) {
        /* fallback 1: Android KEYCODE_WAKEUP=224 through `input` */
        system("/system/bin/input keyevent 224 >/dev/null 2>&1 </dev/null");
        usleep(700 * 1000);
        r = wakefulness_probe(probe, sizeof(probe));
        if (r >= 0) wake_cache_write(probe);
        src = "input224";
        if (r != 1) {
            /* fallback 2: PowerManager.wakeUp() from the global namespace */
            system("/system/bin/su -M -c 'cmd power wakeup' >/dev/null 2>&1 </dev/null");
            usleep(700 * 1000);
            r = wakefulness_probe(probe, sizeof(probe));
            if (r >= 0) wake_cache_write(probe);
            src = "power";
        }
    }
    out("WAKE was=%s now=%s uinput=%d done=1 src=%s probe=%d took=%lldms",
        was, probe[0] ? probe : "unknown", emitted, src, did_probe, now_ms() - t0);
    _exit(0);
}

/* `u` : 鐐逛寒灞忓箷锛堟憞鏉嗗ぇ骞呯Щ鍔ㄦ椂鐢卞簲鐢ㄨ皟鐢級銆? * 绔嬪嵆杩斿洖锛堝彧鍋氭枃浠惰 + 鍙€夌殑涓€娆?uinput 鍐欙級锛屾帰娴?鍏滃簳閮藉湪瀛愯繘绋嬨€? * 涓夌鍒ゅ畾锛? *   缂撳瓨鏄庣‘鈥滈潪 Awake鈥?    鈫?绔嬪埢娉ㄥ叆 KEY_WAKEUP锛屽啀寮傛纭锛? *   缂撳瓨璇粹€淎wake鈥濅笖寰堟柊     鈫?鍏堝紓姝ユ帰娴嬪啀鍐冲畾锛堝彲鑳藉垰鐏睆锛岀紦瀛樿繕娌℃洿鏂帮級锛? *   3s 鍐呴噸澶嶈姹?          鈫?鍘婚噸锛堢┖鎿嶄綔锛夈€?*/
static void cmd_wake_screen(void) {
    char was[32] = {0};
    long long age = -1;
    int st = wake_cached(&age, was, sizeof(was));
    if (!was[0]) snprintf(was, sizeof(was), "unknown");
    long long t0 = now_ms();
    if (t0 - g_last_wake_req_ms < 3000) {
        out("WAKE was=%s now=%s uinput=0 dedup=1 req=1 age=%lldms", was, was, age);
        return;
    }
    g_last_wake_req_ms = t0;
    if (st == 0) {
        int emitted = wake_inject_uinput();
        out("WAKE was=%s now=pending uinput=%d req=1 age=%lldms", was, emitted, age);
        wake_slow_path(was, emitted);
        return;
    }
    if (st == 1) {
        /* 鍙兘鍒氱伃灞忥細鍏堟帰娴嬶紙瀛愯繘绋嬶級锛岀湡鐨勪寒鐫€灏遍浂娉ㄥ叆 */
        out("WAKE was=%s now=pending uinput=0 req=1 probe=1 age=%lldms", was, age);
        wake_slow_path(was, 0);
        return;
    }
    /* 缂撳瓨缂哄け/杩囨湡锛氭寜鈥滀笉纭畾鈥濆鐞嗭紝娉ㄥ叆 KEY_WAKEUP锛堜寒灞忔椂鏄┖鎿嶄綔锛?*/
    int emitted = wake_inject_uinput();
    out("WAKE was=%s now=pending uinput=%d req=1 age=%lldms", was, emitted, age);
    wake_slow_path(was, emitted);
}

/* 鏃х殑鏃犲鎴风鍞ら啋鍏ュ彛锛堟墜鏌勮繛鎺ユ椂鐢級銆傛暣鏉℃參閾捐矾閮藉湪瀛愯繘绋嬮噷璺戯紝
 * 涓诲惊鐜笉鍐嶈 popen/usleep 鍗′綇銆?*/
static void maybe_wake_on_connect(const char *name) {
    time_t now = time(NULL);
    if (now - g_last_wake_at < 3) return;   /* 3 s debounce */
    g_last_wake_at = now;
    pid_t c = fork();
    if (c != 0) return;
    child_quiet_stdio();
    char st[32] = {0};
    int before = wakefulness_probe(st, sizeof(st));
    if (before == 1) {
        out("WAKE skip awake %s", name);
        _exit(0);
    }
    wake_inject_uinput();
    usleep(600 * 1000);
    int after = wakefulness_probe(st, sizeof(st));
    if (after != 1) {
        system("/system/bin/input keyevent 224 >/dev/null 2>&1 </dev/null");
        usleep(600 * 1000);
        after = wakefulness_probe(st, sizeof(st));
        if (after != 1) {
            system("/system/bin/su -M -c 'cmd power wakeup' >/dev/null 2>&1 </dev/null");
            usleep(600 * 1000);
            after = wakefulness_probe(st, sizeof(st));
        }
    }
    if (after >= 0) wake_cache_write(st);
    out("WAKE_CONNECT %s (was %d now %d)", name, before, after);
    _exit(0);
}

/* ------------------------------------- `c`锛氱湡瀹炲厜鏍囦綅缃紙搴旂敤閫昏緫鍧愭爣锛?----
 * `dumpsys input` 鐨?CursorStatesByDisplay 鏄?*鎸?display 鍒嗘**鐨勶紝涓旀閲岀殑
 * hoveringPointers 鏄?**raw natural 鍧愭爣**锛堜緥濡?904脳2316 绔栧睆鐗╃悊绌洪棿锛夛紱
 * 鑰?App 鐨?Display.getSize() 鏄?*閫昏緫绌洪棿**锛堜緥濡?2560脳1600 妯睆锛夈€? * 鏃у疄鐜版壂鍏ㄦ枃鍙栫涓€涓?hoveringPointers锛屼細闅忔満鍛戒腑鍒殑 display锛圚DMI/DeX銆? * display 30/1锛夌殑闄堟棫鐘舵€侊紝闂幆灞呬腑灏变細鎶婂厜鏍囨帹鍒板埆鐨勬樉绀轰笂銆? * 鐜板湪锛氭寜 display 鍒嗘瑙ｆ瀽 鈫?浼樺厛鍙?display 0 鐨?MOUSE hover锛堟病鏈夊氨鍙栫涓€涓? * 鏈?MOUSE hover 鐨?display锛夆啋 鐢ㄨ display 鐨?viewport锛坥rientation /
 * logicalFrame / physicalFrame / deviceSize锛夋妸 raw 鑷劧鍧愭爣鎹㈢畻鎴愰€昏緫鍧愭爣銆? * 鎹㈢畻鍏紡涓?Android InputReader 鐨?rotateAndScaleLocked 涓€鑷达紙ROTATION_90:
 * X=y_raw, Y=naturalWidth-x_raw锛夛紝鍐嶇敤 physicalFrame鈫抣ogicalFrame 缂╂斁骞崇Щ銆? */
#define MAX_VIEWPORTS 8

typedef struct {
    int id;
    int orientation;
    int lx1, ly1, lx2, ly2;
    int px1, py1, px2, py2;
    int dw, dh;
} viewport_t;

static int parse_rect4(const char *s, const char *tag, int *a, int *b, int *c, int *d) {
    const char *p = strstr(s, tag);
    if (!p) return 0;
    return sscanf(p + strlen(tag), "%d, %d, %d, %d", a, b, c, d) == 4;
}

static int parse_pair2(const char *s, const char *tag, int *a, int *b) {
    const char *p = strstr(s, tag);
    if (!p) return 0;
    return sscanf(p + strlen(tag), "%d, %d", a, b) == 2;
}

/* raw natural (闈㈡澘鍘熷鍧愭爣) -> 閫昏緫鍧愭爣锛堜笌 InputReader 鐨勬棆杞崲绠椾竴鑷达級 */
static void raw_to_logical(const viewport_t *v, double rx, double ry, int *out_x, int *out_y) {
    double nw, nh, X, Y;
    if (v->orientation == 1 || v->orientation == 3) { nw = v->dh; nh = v->dw; }
    else { nw = v->dw; nh = v->dh; }
    switch (v->orientation) {
        case 1: X = ry; Y = nw - rx; break;          /* ROTATION_90  */
        case 2: X = nw - rx; Y = nh - ry; break;     /* ROTATION_180 */
        case 3: X = nh - ry; Y = rx; break;          /* ROTATION_270 */
        default: X = rx; Y = ry; break;              /* ROTATION_0   */
    }
    double pw = (double)(v->px2 - v->px1), ph = (double)(v->py2 - v->py1);
    double lw = (double)(v->lx2 - v->lx1), lh = (double)(v->ly2 - v->ly1);
    double lx = v->lx1 + (pw > 1.0 ? (X - v->px1) * lw / pw : 0.0);
    double ly = v->ly1 + (ph > 1.0 ? (Y - v->py1) * lh / ph : 0.0);
    if (lx < v->lx1) lx = v->lx1;
    if (lx > v->lx2) lx = v->lx2;
    if (ly < v->ly1) ly = v->ly1;
    if (ly > v->ly2) ly = v->ly2;
    *out_x = (int)(lx + 0.5);
    *out_y = (int)(ly + 0.5);
}

/* 杩斿洖 1 = 鎵惧埌鍏夋爣锛泂pace=1 琛ㄧず宸叉崲绠楁垚閫昏緫鍧愭爣锛? = 鍙湁 raw 鍧愭爣鍙敤 */
static int cursor_logical(int *out_x, int *out_y, int *out_disp, int *out_space,
                          double *out_raw_x, double *out_raw_y,
                          int *out_frame_x, int *out_frame_w) {
    *out_x = -1; *out_y = -1; *out_disp = -1; *out_space = 0;
    *out_raw_x = -1; *out_raw_y = -1; *out_frame_x = 0; *out_frame_w = 0;
    FILE *p = popen("/system/bin/dumpsys input 2>/dev/null", "r");
    if (!p) return 0;
    viewport_t vps[MAX_VIEWPORTS];
    int nvp = 0;
    memset(vps, 0, sizeof(vps));
    int hov_id[8], hov_mouse[8], nhov = 0;
    double hov_x[8], hov_y[8];
    int in_cursor = 0, cur_disp = -1, cur_has = 0;
    char line[2048];
    while (fgets(line, sizeof(line), p)) {
        if (strstr(line, "Viewport ") && strstr(line, "displayId=")) {
            const char *d = strstr(line, "displayId=");
            int id = d ? atoi(d + strlen("displayId=")) : -1;
            const char *oo = strstr(line, "orientation=");
            int o = oo ? atoi(oo + strlen("orientation=")) : 0;
            int known = 0;
            for (int i = 0; i < nvp; i++) if (vps[i].id == id) known = 1;
            if (id >= 0 && !known && nvp < MAX_VIEWPORTS) {
                viewport_t *v = &vps[nvp];
                memset(v, 0, sizeof(*v));
                v->id = id;
                v->orientation = o;
                v->lx2 = 2560;
                v->ly2 = 1600;
                if (parse_rect4(line, "logicalFrame=[", &v->lx1, &v->ly1, &v->lx2, &v->ly2) &&
                    parse_rect4(line, "physicalFrame=[", &v->px1, &v->py1, &v->px2, &v->py2) &&
                    parse_pair2(line, "deviceSize=[", &v->dw, &v->dh)) {
                    nvp++;
                }
            }
            continue;
        }
        if (strstr(line, "CursorStatesByDisplay:")) { in_cursor = 1; continue; }
        if (!in_cursor) continue;
        /* 缁撴潫鏍囪锛歝ursor 娈典箣鍚庣殑鍏跺畠椤跺眰灏忚妭锛堜袱涓┖鏍肩缉杩涳級 */
        if (line[0] == ' ' && line[1] == ' ' && line[2] != ' ' && strchr(line, ':') &&
            !strstr(line, "hoveringPointers") && !strstr(line, "Windows:")) {
            in_cursor = 0;
            continue;
        }
        /* 鍒嗙粍琛岋紙4 绌烘牸缂╄繘 + displayId + " :"锛夛細"    0 :     Windows:" */
        if (line[0] == ' ' && line[1] == ' ' && line[2] == ' ' && line[3] == ' ' &&
            line[4] >= '0' && line[4] <= '9') {
            cur_disp = atoi(line + 4);
            cur_has = 0;
            continue;
        }
        if (cur_disp < 0 || cur_has) continue;
        if (!strstr(line, "hoveringPointers=[Pointer")) continue;
        char *at = strstr(line, "at (");
        if (!at) continue;
        double rx = 0, ry = 0;
        if (sscanf(at + 4, "%lf, %lf", &rx, &ry) != 2) continue;
        if (nhov < 8) {
            hov_id[nhov] = cur_disp;
            hov_mouse[nhov] = strstr(line, "MOUSE") != NULL;
            hov_x[nhov] = rx;
            hov_y[nhov] = ry;
            nhov++;
            cur_has = 1;
        }
    }
    pclose(p);
    if (nhov <= 0) return 0;
    /* 浼樺厛 display 0锛涘惁鍒欑涓€涓?MOUSE hover锛涘啀鍚﹀垯绗竴涓?*/
    int pick = -1;
    for (int i = 0; i < nhov; i++) if (hov_id[i] == 0) { pick = i; break; }
    if (pick < 0) for (int i = 0; i < nhov; i++) if (hov_mouse[i]) { pick = i; break; }
    if (pick < 0) pick = 0;
    *out_disp = hov_id[pick];
    *out_raw_x = hov_x[pick];
    *out_raw_y = hov_y[pick];
    const viewport_t *v = NULL;
    for (int i = 0; i < nvp; i++) if (vps[i].id == hov_id[pick]) { v = &vps[i]; break; }
    if (v) {
        raw_to_logical(v, hov_x[pick], hov_y[pick], out_x, out_y);
        *out_space = 1;
        *out_frame_x = v->px1;
        *out_frame_w = v->px2 - v->px1;
    } else {
        *out_x = (int)(hov_x[pick] + 0.5);
        *out_y = (int)(hov_y[pick] + 0.5);
        *out_space = 0;
    }
    return 1;
}

/* `c` : 鐪熷疄鍏夋爣浣嶇疆锛圓pp 鍋氬眳涓棴鐜爣瀹氭椂鐢級銆? * `dumpsys input` 鍦ㄥ瓙杩涚▼閲岃窇锛屼富寰幆闆堕樆濉烇紱
 * 鍥炲寘 `CURSOR <lx> <ly> display=<id> space=logical [frame=<x,w> raw=<rx>,<ry>]`锛? * 鎵句笉鍒颁负 `CURSOR -1 -1 display=-1`銆?*/
static void cmd_cursor_query(void) {
    long long t0 = now_ms();
    pid_t c = fork();
    if (c < 0) { out("ERR cursor fork: %s", strerror(errno)); return; }
    if (c != 0) {
        out("CURSORQ pid=%d", (int)c);
        return;
    }
    child_quiet_stdio();
    int x = -1, y = -1, disp = -1, space = 0, fx = 0, fw = 0;
    double rx = -1, ry = -1;
    int found = cursor_logical(&x, &y, &disp, &space, &rx, &ry, &fx, &fw);
    if (!found) {
        out("CURSOR -1 -1 display=-1 took=%lldus", now_ms() - t0);
    } else if (space) {
        out("CURSOR %d %d display=%d space=logical frame=%d,%d raw=%.1f,%.1f took=%lldus",
            x, y, disp, fx, fw, rx, ry, now_ms() - t0);
    } else {
        out("CURSOR %d %d display=%d space=raw frame=%d,%d took=%lldus",
            x, y, disp, fx, fw, now_ms() - t0);
    }
    _exit(0);
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
            /* 鏈夊彸鎽囨潌鐨勬墜鏌勶細Z/RZ 鏄壋鏈猴紝鎸?0..1 褰掍竴锛堝惁鍒欒鎸夊埌 75% 鎵嶈Е鍙戯級 */
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

/* 榧犳爣璁惧鍙兘琚€岀┖闂查殣钘忋€嶉攢姣佷簡锛氫换浣曚竴娆＄Щ鍔?鐐瑰嚮鍓嶉兘纭繚瀹冨瓨鍦紝
 * 鍚﹀垯 App 渚х姸鎬佷竴鏃︿笉鍚屾锛屽氨浼氳〃鐜颁负銆屽厜鏍囦笉瑙佷簡/鐐逛簡娌″弽搴斻€嶃€?*/
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

/* pointer movement gain (REL delta -> on-screen pixels). 3.24~3.25 measured on
 * the SM-F9360 at pointer_speed=-1 (DIAG v166 搂4); it changes with the system
 * pointer speed, so the app can read/set it through the `g` command. */
static double g_pointer_gain = 3.25;

/* the gain that actually converts display pixels -> REL units */
static double effective_gain(void) {
    if (g_center_gain > 0.2 && g_center_gain < 20.0) return g_center_gain;
    if (g_pointer_gain > 0.2 && g_pointer_gain < 20.0) return g_pointer_gain;
    return 2.16;
}

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
/* 灞呬腑锛氬厛鐢?澶氫釜鏈夌晫灏忔"鎶婃寚閽堟帹鍒板乏涓婅锛堜竴涓?-30000 鐨勫ぇ浣嶇Щ浼氭妸鎸囬拡鐢╁嚭灞忓箷銆? * 涔嬪悗杩?hover 閮芥病鏈夛級锛屽啀鎸夊鐩婁竴姝ヨ蛋鍒板睆骞曚腑蹇冦€? * 鐢ㄦ硶锛歄 <w> <h> <park> <rot> [gain] */
/* 鎶婃寚閽堟斁鍒板睆骞曚笂鐨勪换鎰忕粷瀵瑰潗鏍囷細鍏堟湁鐣屾杩涘埌宸︿笂瑙?0,0)锛屽啀鎸夊鐩婁竴姝ュ埌 (tx,ty)銆? * 鍥犱负銆屽埌宸︿笂瑙掋€嶆槸鏈夌晫涓斾細鎾炲埌灞忓箷杈圭紭鐨勶紝鎵€浠ヤ笉绠℃寚閽堝綋鍓嶅湪鍝兘鑳藉榻愬埌 (0,0)锛? * 杩欐牱閲嶅缓榧犳爣璁惧鍚庝篃鑳界簿纭湴鎶婂厜鏍囨斁鍥?涓婃鐨勪綅缃?銆?*/
static void pointer_goto(int tx, int ty, int maxX, int maxY) {
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    g_disp_w = maxX;
    g_disp_h = maxY;
    if (tx < 0) tx = 0;
    if (ty < 0) ty = 0;
    if (tx > maxX) tx = maxX;
    if (ty > maxY) ty = maxY;
    double gain = effective_gain();
    if (g_mouse < 0) {
        g_mouse = make_mouse();
        usleep(120 * 1000);
        out("POINTER on (goto)");
    }
    double totalX = -(double)maxX * 1.2 / gain;
    double totalY = -(double)maxY * 1.2 / gain;
    const int STEPS = 40;
    for (int i = 0; i < STEPS; i++) {
        cmd_mouse_move(totalX / STEPS, totalY / STEPS);
        usleep(6 * 1000);
    }
    usleep(40 * 1000);
    cmd_mouse_move((double)tx / gain, (double)ty / gain);
}

static void cmd_center(int maxX, int maxY, int park, int rot) {
    (void)park; (void)rot;
    if (maxX <= 0) maxX = 2560;
    if (maxY <= 0) maxY = 1600;
    double gain = effective_gain();
    pointer_goto(maxX / 2, maxY / 2, maxX, maxY);
    out("CENTER(steps+gain %.2f) rot=%d -> %d,%d", gain, rot, maxX / 2, maxY / 2);
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

/* 鑳藉惁鍒涘缓/娉ㄥ叆 uinput 璁惧锛堥紶鏍?閿洏/婊氳疆鐨勮兘鍔?= uinput 鑺傜偣鍙啓锛夈€? * 娉ㄦ剰锛氫笉鑳界敤鈥滆櫄鎷熼紶鏍囧綋鍓嶆槸鍚﹀凡鎵撳紑鈥濆綋鑳藉姏鈥斺€旂┖闂查殣钘忥紙h锛変細鎶婇紶鏍囪澶囬攢姣侊紝
 * 閭ｅ彧鏄繍琛屾椂鐘舵€侊紝鑳藉姏涓€鐩村瓨鍦ㄣ€?*/
static int uinput_capable(void) {
    return (access("/dev/uinput", W_OK) == 0 ||
            access("/dev/input/uinput", W_OK) == 0) ? 1 : 0;
}

/* 鏄惁鑳芥灇涓?鎶撳彇 /dev/input 涓嬬殑鎵嬫焺锛堣兘鍔涳紱鍏蜂綋鎶撳埌鍑犱釜璧?CAP devices 鏁伴噺锛?*/
static int input_enum_capable(void) {
    return access("/dev/input", R_OK | X_OK) == 0 ? 1 : 0;
}

/* 鏄惁鏈夋墜鏌勫浜?grab 鐘舵€侊紙INFO 鐢紝涓嶆槸鑳藉姏锛?*/
static int any_device_grabbed(void) {
    for (int i = 0; i < g_ndev; i++)
        if (g_devs[i].grabbed) return 1;
    return 0;
}

/* 閾捐矾鑷 (閫氱敤 搂8.1): one line per capability.
 * 鍙ｅ緞锛坴1.66-r4锛宼11 淇锛夛細
 *   CAP <name> <0|1>  鈥斺€?**鑳藉姏**锛屼笉鏄繍琛屾椂鐘舵€併€傝兘鍔涘瓨鍦?1锛堜緥濡?uinput 鑺傜偣鍙啓銆? *                        娉ㄥ叆浜岃繘鍒跺彲鎵ц锛夛紱鍙湁鐪熺殑缂轰緷璧栨墠 0銆侫pp 璁剧疆椤垫妸鎵€鏈? *                        CAP 0 鏄剧ず涓恒€岀己澶便€嶏紝鎵€浠ヨ繖閲岀粷涓嶈兘涓婃姤鐬椂鐘舵€併€? *   CAP devices <n>   鈥斺€?渚嬪锛氬綋鍓嶆姄鍒扮殑娓告垙鎵嬫焺**鏁伴噺**锛? = 娌℃帴鎵嬫焺锛? *                        涓嶄唬琛ㄨ兘鍔涚己澶憋紱璁剧疆椤典細鏄剧ず涓恒€岀己澶便€嶏紝灞炰簬濡傚疄鍙嶆槧鈥滄病鏈夋墜鏌勨€濓級銆? *                        鑳藉姏椤瑰彟瑙?CAP gamepad锛堣兘鍚︽灇涓?鎶撳彇鎵嬫焺锛夈€? *   CAP screen        鈥斺€?銆岃兘璇诲埌灞忓箷鐘舵€併€嶇殑鑳藉姏锛坉umpsys power 閲岃兘瑙ｆ瀽鍒? *                        mWakefulness锛夛紝涓嶆槸褰撳墠鏄惁浜睆銆? *   INFO ...          鈥斺€?杩愯鏃剁姸鎬?璇婃柇淇℃伅锛屼笉鍙備笌鈥滅己澶扁€濆垽瀹? *                        锛堝 INFO pointer device=on|off锛氭寚閽堣澶囧綋鍓嶆槸鍚﹀凡鍒涘缓锛夈€? */
static void cmd_selftest(void) {
    int ui = uinput_capable();
    out("SELFTEST begin");
    out("CAP mouse %d", ui);                 /* 鑳藉惁鍒涘缓/娉ㄥ叆 uinput 榧犳爣锛堣兘鍔涳級 */
    out("CAP kbd %d", ui);                   /* 鑳藉惁鍒涘缓/娉ㄥ叆 uinput 閿洏锛堣兘鍔涳級 */
    out("CAP wheel %d", ui);                 /* 婊氳疆璧板悓涓€涓?uinput 榧犳爣锛堣兘鍔涳級 */
    out("CAP swipe %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP notif %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("CAP power %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("CAP force %d", access("/system/bin/cmd", X_OK) == 0 ? 1 : 0);
    out("INFO apex %d", access("/apex/com.android.art/lib64/libnativeloader.so", R_OK) == 0 ? 1 : 0);
    out("CAP screen %d", screen_awake_readable());
    out("CAP wake %d", (ui || access("/system/bin/input", X_OK) == 0) ? 1 : 0);
    out("CAP cursor %d", access("/system/bin/dumpsys", X_OK) == 0 ? 1 : 0);
    out("CAP gamepad %d", input_enum_capable());   /* 鑳藉惁鏋氫妇/鎶撳彇鎵嬫焺锛堣兘鍔涳級 */
    out("CAP devices %d", g_ndev);                 /* 鏁伴噺锛? = 鏈帴鎵嬫焺锛堢湡瀹炵姸鎬侊級 */
    /* 涓茶鎵嬪娍闃熷垪鐨勮兘鍔?= 娉ㄥ叆鍣ㄥ彲鐢紙input 鍙墽琛岋級锛沚usy 鍙槸杩愯鏃剁姸鎬侊紝鏀?INFO */
    out("CAP gesture %d", access("/system/bin/input", X_OK) == 0 ? 1 : 0);
    out("INFO pointer device=%s", g_mouse >= 0 ? "on" : "off");
    out("INFO kbd device=%s", g_kbd >= 0 ? "on" : "off");
    out("INFO gesture busy=%d queued=%d", gesture_busy() ? 1 : 0, gesture_queued());
    out("INFO devices_grabbed=%d", any_device_grabbed());
    out("SELFTEST end");
}

/* 璇诲彇褰撳墠鍓嶅彴鍖呭悕锛坱opResumedActivity锛夈€? *
 * `dumpsys activity activities` 瑕?100~300 ms锛屽鏋滅洿鎺ュ湪鍛戒护寰幆閲屽悓姝ヨ窇锛? * 姣?2 绉掑氨浼氬崱浣忚緭鍏ュ鐞嗕竴娆★紙娓告垙涓兘鎰熻鍒伴】锛夈€傛墍浠ヨ繖閲屾敼鎴愶細
 *   1) 绔嬪嵆杩斿洖涓婁竴娆＄紦瀛樼殑缁撴灉锛?data/adb/gpm/top.txt锛? *   2) 鍚庡彴 fork 涓€涓瓙杩涚▼鍘诲埛鏂扮紦瀛橈紝涓嬩竴娆℃煡璇㈠氨鏄柊鐨? * 鍓嶅彴鍖呭悕鍙敤浜庛€屾闈?绯荤粺寮圭獥銆嶅垽瀹氾紝鏅?2 绉掑畬鍏ㄦ病闂銆?*/
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
    /* 瀛愯繘绋嬶細璺?dumpsys锛屾妸鍖呭悕鍐欒繘缂撳瓨鏂囦欢 */
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
    /* 缂撳瓨涓虹┖鏃跺悓姝ユ煡涓€娆★紝淇濊瘉绗竴娆¤皟鐢ㄥ氨鏈夊€?*/
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
        /* 鏈夌紦瀛橈細璁╁瓙杩涚▼鍘诲埛鏂帮紝涓诲惊鐜珛鍒昏繑鍥?*/
        top_cache_refresh_async();
    }
}

/* ---------------------------------------------------------------- 婊戝姩鐢ㄧ殑缂撳瓨
 * 鏃у疄鐜帮紙DIAG v166 搂2 瀹炴祴锛夋湁 4 涓棶棰橈紝鍏ㄩ儴鍦ㄨ繖閲屼慨鎺夛細
 *   1) 鍙湁涓€浠?/data/adb/gpm/taskbounds.txt锛歞isplay 0/1 浜掔浉瑕嗙洊锛? *   2) 鍒锋柊澶辫触鏃跺啓 "0 0 maxX maxY"(鍏ㄥ睆)锛岃捣鎵嬬偣浠?task 涓績璺冲埌灞忓箷涓績锛? *   3) 缂撳瓨姘镐笉杩囨湡銆佷笉鏍￠獙褰掑睘锛氬垏搴旂敤鍚?2s 鍐呮粦鍔ㄤ細钀借繘涓婁竴涓簲鐢ㄧ殑鍖哄煙锛? *   4) 鍒锋柊 fork 鍦?cmd_swipe 鍐呴儴锛屾粦鍔ㄧ涓€甯х櫧浠樹竴娆?fork銆? * 鐜板湪锛? *   - 姣?display 涓€浠?/data/adb/gpm/taskbounds-<display>.txt
 *   - 鍐呭 "pkg x1 y1 x2 y2 w h"锛氬寘鍚?+ 鍒嗚鲸鐜囬兘瑕佷笌褰撳墠涓€鑷存墠鍙俊
 *   - 璇诲彇鏃舵牎楠岋細灞忓箷鍐呫€?=120x120銆乵time<=4s銆佸寘鍚?== g_top_pkg锛堣嫢宸茬煡锛? *   - 浠讳綍涓€椤逛笉婊¤冻 鈫?鍏ㄥ睆杈圭晫锛堝喅瀹氳锛屼笉浼氳鈥滄瘨鍖栤€濈殑鐭╁舰甯﹀亸锛夛紝
 *     骞剁疆 flag 璁╀富寰幆鍘诲埛鏂帮紙cmd_swipe 鑷韩涓嶅啀 fork锛? */
#define BOUNDS_CACHE_LEGACY "/data/adb/gpm/taskbounds.txt"
#define BOUNDS_STALE_MS 4000

static int g_bounds_need_refresh = 0;
static int g_bounds_want_display = -1;
static int g_bounds_want_w = 0, g_bounds_want_h = 0;
static int g_bounds_force_refresh = 0;   /* 鍛ㄦ湡鍒锋柊锛氱粫杩?mtime 鑺傛祦锛堝懆鏈熸湰韬嵆鑺傛祦锛?*/
/* 鏈€杩戜竴娆℃粦鍔ㄧ敤鍒扮殑 display/鍒嗚鲸鐜囷細涓诲惊鐜瘡 2s 涓诲姩鍒锋柊涓€娆★紝淇濊瘉琚啓鍧忕殑
 * 缂撳瓨锛堟姇姣掞級鏈€澶?2s 灏辫鐪熷疄鍊艰鐩?*/
static int g_bounds_last_display = -1;
static int g_bounds_last_w = 0, g_bounds_last_h = 0;

/* 鏈€杩戜竴娆″凡鐭ョ殑鍏夋爣浣嶇疆锛圓pp 浼犺繘鏉ョ殑锛夛紝鐢ㄤ簬娌℃湁鏄惧紡浼犲潗鏍囨椂鐨勫洖閫€ */
static int g_ptr_x = -1, g_ptr_y = -1;

static void bounds_cache_path(int display, char *out, size_t n) {
    snprintf(out, n, "/data/adb/gpm/taskbounds-%d.txt", display);
}

static int bounds_cache_read(int display, int maxX, int maxY,
                             int *x1, int *y1, int *x2, int *y2) {
    char path[96];
    bounds_cache_path(display, path, sizeof(path));
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    char pkg[160] = {0};
    int a = 0, b = 0, c = 0, d = 0, w = 0, h = 0;
    int got = fscanf(f, "%159s %d %d %d %d %d %d", pkg, &a, &b, &c, &d, &w, &h);
    fclose(f);
    if (got != 7) return 0;
    if (w != maxX || h != maxY) return 0;              /* 鍒嗚鲸鐜?鏃嬭浆鍙樹簡 */
    if (pkg[0] && pkg[0] != '-') {
        /* 褰掑睘鏍￠獙锛氱紦瀛橀噷鐨勫墠鍙板寘蹇呴』杩樻槸 App 鐜板湪鐪嬪埌鐨勫墠鍙板寘銆?         * top.txt 鐢?'t' 鏌ヨ/鍚庡彴鍒锋柊缁存姢锛堣法杩涚▼鍙锛夛紝姣斿唴瀛樺彉閲忓彲闈犮€?*/
        char top[192] = {0};
        top_cache_read(top, sizeof(top));
        if (top[0] && strcmp(pkg, top) != 0) return 0;
    }
    if (a < -8 || b < -8 || c > maxX + 8 || d > maxY + 8) return 0;
    if (c - a < 120 || d - b < 120) return 0;
    struct stat st;
    if (stat(path, &st) != 0) return 0;
    long long age_ms = (long long)(time(NULL) - st.st_mtime) * 1000;
    if (age_ms > BOUNDS_STALE_MS) return 0;
    *x1 = a; *y1 = b; *x2 = c; *y2 = d;
    return 1;
}

/* force=1锛氫富寰幆鐨勫懆鏈熷埛鏂帮紙鍛ㄦ湡鏈韩宸叉槸鑺傛祦锛屽繀椤荤粫杩?mtime 鑺傛祦锛? * 鍚﹀垯鎶曟瘨鍚庣殑绗竴涓?tick 鍙兘钀藉湪 mtime<2s 绐楀彛閲岃涓㈡帀锛屾渶鍧忚绛?~4s锛夛紱
 * force=0锛氭粦鍔ㄨ矾寰勭殑鎸夐渶鍒锋柊锛堜繚鐣?2s 鑺傛祦锛岄伩鍏嶆瘡娆℃粦鍔ㄩ兘 fork dumpsys锛夈€?*/
static void bounds_refresh_request(int display, int maxX, int maxY, int force) {
    g_bounds_need_refresh = 1;
    g_bounds_want_display = display;
    g_bounds_want_w = maxX;
    g_bounds_want_h = maxY;
    if (force) g_bounds_force_refresh = 1;
}

/* 涓诲惊鐜皟鐢細鐪熸 fork 鍒锋柊瀛愯繘绋嬶紱婊戝姩璺緞涓嶅啀浠樿繖涓紑閿€ */
static void bounds_refresh_poll(void) {
    if (!g_bounds_need_refresh) return;
    int display = g_bounds_want_display, maxX = g_bounds_want_w, maxY = g_bounds_want_h;
    int force = g_bounds_force_refresh;
    g_bounds_need_refresh = 0;
    g_bounds_force_refresh = 0;
    if (display < 0 || maxX <= 0 || maxY <= 0) return;
    char path[96];
    bounds_cache_path(display, path, sizeof(path));
    struct stat st;
    if (!force && stat(path, &st) == 0 && time(NULL) - st.st_mtime < 2)
        return;                                                        /* 浠呮粦鍔ㄨ矾寰勪繚鐣?2s 鑺傛祦 */
    pid_t c = fork();
    if (c != 0) return;
    devnull_redirect();
    FILE *t = popen("dumpsys activity activities 2>/dev/null", "r");
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY, found = 0;
    char pkg[160] = {0};
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
                char *u = strstr(tl, "u0 ");
                if (u) {
                    u += 3;
                    size_t i = 0;
                    while (u[i] && u[i] != '/' && u[i] != ' ' && i + 1 < sizeof(pkg)) {
                        pkg[i] = u[i];
                        i++;
                    }
                    pkg[i] = 0;
                }
                if (have && since <= 12 && r0 > l0 && b0 > t0 &&
                    r0 <= maxX + 200 && b0 <= maxY + 200) {
                    bx1 = l0; by1 = t0; bx2 = r0; by2 = b0; found = 1;
                }
                break;
            }
        }
        pclose(t);
    }
    /* 鏃犺瑙ｆ瀽鎴愬姛涓庡惁閮藉啓涓€浠藉甫褰掑睘淇℃伅鐨勭紦瀛橈紙澶辫触鏃舵槸鈥?鈥濆叏灞忥級锛?     * 璁╀笅涓€娆℃粦鍔ㄦ湁鍐冲畾璁虹殑缁撴灉锛屼篃閬垮厤姣忓抚閲嶈瘯 */
    if (!found) { bx1 = 0; by1 = 0; bx2 = maxX; by2 = maxY; }
    FILE *f = fopen(path, "w");
    if (f) {
        fprintf(f, "%s %d %d %d %d %d %d\n", pkg[0] ? pkg : "-", bx1, by1, bx2, by2, maxX, maxY);
        fclose(f);
    }
    if (display == 0) {
        /* 鍏煎纾佺洏璇婃柇鑴氭湰锛歭egacy 鏂囦欢浠嶅啓 4 涓暟瀛?*/
        FILE *lf = fopen(BOUNDS_CACHE_LEGACY ".tmp", "w");
        if (lf) {
            fprintf(lf, "%d %d %d %d\n", bx1, by1, bx2, by2);
            fclose(lf);
            rename(BOUNDS_CACHE_LEGACY ".tmp", BOUNDS_CACHE_LEGACY);
        }
    }
    _exit(0);
}

/* ---------------------------------------------------------------- 鎵嬪娍涓茶闃熷垪
 * `input swipe` 姣忔璧蜂竴鏉＄嫭绔嬫敞鍏ユ祦锛涗袱鏉″悓鏃跺湪椋炰細浜掔浉鍚炲苟锛圖IAG 瀹炴祴锛? * 搴旂敤鍙敹鍒?1 click / 0 TOUCH锛夈€傝繖閲屽仛鐪熸鐨勪覆琛屾敞鍏ワ細
 *   - 浠绘剰鏃跺埢鏈€澶?1 鏉?input swipe 鍦ㄩ锛? *   - 鍦ㄩ锛堟垨鍒氱粨鏉熺殑鎹㈣酱淇濇姢绐楀唴锛夋椂锛?*鍙︿竴杞?*鐨勬墜鍔跨洿鎺ヤ涪寮冨苟鎵? *     SWIPE_DROP锛堣繖鏄€滀竴娆℃墜鍔垮彧浣滅敤涓€涓尯鍩熲€濈殑纭繚璇侊級锛? *   - 鍚岃酱鎵嬪娍杩?1 娣卞害绛夊緟闃熷垪锛屾寜椤哄簭鎵ц锛屼笉涓㈠綋鍓嶆柟鍚戯紱
 *   - 姣忔潯娉ㄥ叆 start/done 鎴愬鍑虹幇鍦?helper.log锛堝彲璇佷吉锛氭病鏈夊苟鍙戯級銆? */
#define SWIPE_QUEUE_MAX 2
#define SWIPE_SETTLE_MS 60       /* 涓婁竴鏉＄粨鏉熷悗璁╃郴缁熷鐞嗗畬 UP */
#define SWIPE_AXIS_GUARD_MS 90   /* 鎹㈣酱淇濇姢绐楋細鍒氭粦瀹岀珛鍒诲弽鍚戣涓轰覆鎵?*/

typedef struct {
    int display;
    int x1, y1, x2, y2;
    int ms;
    int vertical;
    int is_notif;
    int queued;                  /* started from the queue (prep measured at enqueue) */
    int tx1, tx2, ty1, ty2;      /* 浠呯敤浜庢棩蹇楋紙task 杈圭晫锛?*/
} swipe_req_t;

static swipe_req_t g_q[SWIPE_QUEUE_MAX];
static int g_qn = 0;
static pid_t g_swipe_pid = 0;
static int g_swipe_axis = -1;
static int g_swipe_is_notif = 0;
static int g_swipe_display = 0;
static long long g_swipe_started_ms = 0;
static long long g_swipe_ended_ms = 0;
static long long g_swipe_next_at_ms = 0;
static unsigned long g_swipe_seq = 0;

static const char *axis_name(int vertical) { return vertical ? "Z" : "V"; }

static void swipe_spawn(const swipe_req_t *r, long long prep_us) {
    char d[16], x1[16], y1[16], x2[16], y2[16], ms[16];
    snprintf(d, sizeof(d), "%d", r->display);
    snprintf(x1, sizeof(x1), "%d", r->x1);
    snprintf(y1, sizeof(y1), "%d", r->y1);
    snprintf(x2, sizeof(x2), "%d", r->x2);
    snprintf(y2, sizeof(y2), "%d", r->y2);
    snprintf(ms, sizeof(ms), "%d", r->ms);
    char *argv[] = {"input", "-d", d, "swipe", x1, y1, x2, y2, ms, NULL};
    pid_t pid = spawn_exec("/system/bin/input", argv);
    if (pid < 0) { out("ERR swipe fork: %s", strerror(errno)); return; }
    g_swipe_seq++;
    g_swipe_pid = pid;
    g_swipe_axis = r->vertical;
    g_swipe_is_notif = r->is_notif;
    g_swipe_display = r->display;
    g_swipe_started_ms = now_ms();
    if (r->is_notif) {
        out("NOTIF swipe async n=%lu pid=%d prep=%lldus", g_swipe_seq, (int)pid, prep_us);
    } else {
        out("SWIPE %d %d,%d -> %d,%d (task %d..%d / %d..%d) axis=%s n=%lu pid=%d queued=%d async prep=%lldus",
            r->display, r->x1, r->y1, r->x2, r->y2, r->tx1, r->tx2, r->ty1, r->ty2,
            axis_name(r->vertical), g_swipe_seq, (int)pid, r->queued, prep_us);
    }
}

/* submit one gesture: starts it, queues it (same axis) or drops it (other axis) */
static void swipe_submit(swipe_req_t r, long long prep_us) {
    long long now = now_ms();
    if (g_swipe_pid > 0) {
        if (r.vertical != g_swipe_axis) {
            out("SWIPE_DROP axis=%s busy=%s n=%lu x=%d,y=%d reason=crosstalk",
                axis_name(r.vertical), axis_name(g_swipe_axis), g_swipe_seq, r.x1, r.y1);
            return;
        }
        if (g_qn < SWIPE_QUEUE_MAX) {
            g_q[g_qn++] = r;
            out("SWIPE_QUEUED axis=%s depth=%d n=%lu x=%d,y=%d",
                axis_name(r.vertical), g_qn, g_swipe_seq, r.x1, r.y1);
        } else {
            out("SWIPE_DROP axis=%s busy=%s n=%lu reason=queue_full",
                axis_name(r.vertical), axis_name(g_swipe_axis), g_swipe_seq);
        }
        return;
    }
    if (g_swipe_ended_ms > 0 && r.vertical != g_swipe_axis &&
        now - g_swipe_ended_ms < SWIPE_AXIS_GUARD_MS) {
        out("SWIPE_DROP axis=%s last=%s age=%lldms reason=axis_guard x=%d,y=%d",
            axis_name(r.vertical), axis_name(g_swipe_axis), now - g_swipe_ended_ms, r.x1, r.y1);
        return;
    }
    swipe_spawn(&r, prep_us);
}

/* called from reap_children() for every reaped child */
static void gesture_reap(pid_t pid, int st) {
    if (pid <= 0 || pid != g_swipe_pid) return;
    int rc = WIFEXITED(st) ? WEXITSTATUS(st) : -1;
    long long dur = now_ms() - g_swipe_started_ms;
    if (g_swipe_is_notif) {
        out("NOTIF swipe rc=%d dur=%lldms n=%lu", rc, dur, g_swipe_seq);
    } else {
        out("SWIPE_DONE %d axis=%s n=%lu rc=%d dur=%lldms",
            g_swipe_display, axis_name(g_swipe_axis), g_swipe_seq, rc, dur);
    }
    g_swipe_pid = 0;
    g_swipe_ended_ms = now_ms();
    g_swipe_next_at_ms = g_swipe_ended_ms + SWIPE_SETTLE_MS;
}

/* start the next queued gesture when its settle window has passed */
static void gesture_poll(void) {
    if (g_swipe_pid > 0 || g_qn <= 0) return;
    if (now_ms() < g_swipe_next_at_ms) return;
    swipe_req_t r = g_q[0];
    for (int i = 1; i < g_qn; i++) g_q[i - 1] = g_q[i];
    g_qn--;
    r.queued = 1;
    swipe_spawn(&r, 0);
}

static int gesture_busy(void) { return g_swipe_pid > 0 || g_qn > 0; }
static int gesture_queued(void) { return g_qn; }

/* poll() timeout so a queued gesture starts on time without busy-waiting */
static int gesture_poll_timeout(void) {
    if (!gesture_busy()) return 400;
    if (g_swipe_pid > 0) return 40;
    long long d = g_swipe_next_at_ms - now_ms();
    if (d <= 0) return 1;
    return d > 40 ? 40 : (int)d;
}

static void cmd_swipe(int display, int delta, int ms, int maxX, int maxY, int vertical, int startPct,
                      int have_cursor, int cursor_x, int cursor_y) {
    if (delta == 0) return;
    struct timespec t_start, t_end;
    clock_gettime(CLOCK_MONOTONIC, &t_start);
    if (display < 0) display = 0;
    if (maxX <= 0) maxX = g_disp_w > 0 ? g_disp_w : 2560;
    if (maxY <= 0) maxY = g_disp_h > 0 ? g_disp_h : 1600;
    /* foreground task bounds: the swipe must start inside the app, otherwise
     * it lands on the desktop and nothing scrolls. The bounds of the focused
     * task appear just above its topResumedActivity line; taking the first
     * mBounds in the dump would return the root task (full display) and let
     * the pointer anchor land on the desktop. */
    int bx1 = 0, by1 = 0, bx2 = maxX, by2 = maxY;
    g_bounds_last_display = display;
    g_bounds_last_w = maxX;
    g_bounds_last_h = maxY;
    if (!bounds_cache_read(display, maxX, maxY, &bx1, &by1, &bx2, &by2)) {
        bx1 = 0; by1 = 0; bx2 = maxX; by2 = maxY;
        /* 缂撳瓨涓嶅彲淇★細鏈鐢ㄥ叏灞忥紝鍒锋柊浜ょ粰涓诲惊鐜紙涓嶅湪婊戝姩璺緞 fork锛?*/
        bounds_refresh_request(display, maxX, maxY, 0);   /* 滑动路径：保留 2s 节流 */
    }

    int x = (bx1 + bx2) / 2, y = (by1 + by2) / 2;
    /* 鍏夋爣浣嶇疆锛氫紭鍏堢敤鍛戒护閲屽甫鐨勫潗鏍囷紙App 浼犵殑锛夛紝鍏舵鐢ㄤ笂娆″凡鐭ュ€硷紱
     * 閮戒笉琛屽氨钀藉湪 task 涓績銆備笉鍐嶈皟鐢?dumpsys input銆?*/
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
    /* 鎵嬪娍淇濇姢鍖猴細浠庨《閮?12% 寰€涓嬬殑婊戝姩浼氳绯荤粺/妗岄潰褰撴垚銆屾媺閫氱煡鏍忋€嶏紝
     * 鎵€浠ュ悜涓嬬殑婊戝姩蹇呴』浠庝繚鎶ゅ尯浠ヤ笅璧锋墜锛堣繖鏄闈笅婊戞媺鍑虹姸鎬佹爮鐨勬牴鍥狅級銆?*/
    if (vertical && delta > 0) {
        int guard = by1 + (by2 - by1) * 12 / 100;
        if (y < guard) { y = guard; y2 = guard + delta; }
        if (y2 > by2 - 20) y2 = by2 - 20;
    }
    /* 鏈€缁堝す鍒板睆骞曞唴锛氳秺鐣屽潗鏍?`input` 浼氱洿鎺ヤ涪寮冩暣鏉℃墜鍔?*/
    if (x < 0) x = 0;
    if (x > maxX) x = maxX;
    if (y < 0) y = 0;
    if (y > maxY) y = maxY;
    if (x2 < 0) x2 = 0;
    if (x2 > maxX) x2 = maxX;
    if (y2 < 0) y2 = 0;
    if (y2 > maxY) y2 = maxY;
    if (ms <= 0) ms = 480;
    swipe_req_t r;
    memset(&r, 0, sizeof(r));
    r.display = display;
    r.x1 = x; r.y1 = y; r.x2 = x2; r.y2 = y2;
    r.ms = ms;
    r.vertical = vertical ? 1 : 0;
    r.is_notif = 0;
    r.tx1 = bx1; r.tx2 = bx2; r.ty1 = by1; r.ty2 = by2;
    clock_gettime(CLOCK_MONOTONIC, &t_end);
    long long prep_us = (long long)(t_end.tv_sec - t_start.tv_sec) * 1000000 +
                        (t_end.tv_nsec - t_start.tv_nsec) / 1000;
    swipe_submit(r, prep_us);
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
    /* 鐪熸鏉€锛歛m force-stop + 鐩存帴 SIGKILL 鍏滃簳锛堜繚璇?纭疄姝讳簡"锛?*/
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
     * activity of the same app 鈥?which looks like nothing happened. */
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

/* Android keycode -> Linux input code锛堝彧瑕嗙洊鏄犲皠琛ㄩ噷浼氱敤鍒扮殑缁勫悎閿級 */
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
        case 187: return 580;  /* APP_SWITCH锛堝浠诲姟/鏈€杩戜换鍔★級*/
        case 3:   return 172;  /* HOME -> KEY_HOMEPAGE */
        case 24:  return 115;  /* VOLUME_UP */
        case 25:  return 114;  /* VOLUME_DOWN */
        case 164: return 113;  /* MUTE */
        case 85:  return 164;  /* MEDIA_PLAY_PAUSE */
        case 87:  return 163;  /* MEDIA_NEXT */
        case 88:  return 165;  /* MEDIA_PREVIOUS */
        /* 甯哥敤瀛楃 / 鍔熻兘閿紙鑷畾涔夊揩鎹烽敭鐢級 */
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
        case 120: return 99;   /* SYSRQ (鎴浘) */
        /* DPAD_CENTER锛歋amsung 涓?KEY_OK(352) 涓嶄細瑙﹀彂纭锛孠EY_ENTER(28) 鍙互
         * 锛堝疄娴?KEY_SELECT 353 / KPENTER 96 涔熷彲浠ワ紝鍙栨渶閫氱敤鐨?ENTER锛?*/
        case 23:  return 28;
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

/* 渚濇鎸変笅锛屽啀閫嗗簭閲婃斁锛欳trl+Minus 杩欑被缁勫悎鎵嶄細琚簲鐢ㄥ綋鎴愨€滄寜浣忕粍鍚堚€?*/
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
 * release both 鈥?this is what the DeX app switcher expects (a bare
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

/* read the first non-empty line of a file (child-process helper) */
static void read_first_line(const char *path, char *out, size_t n) {
    out[0] = 0;
    FILE *f = fopen(path, "r");
    if (!f) return;
    while (fgets(out, (int)n, f)) {
        char *nl = strpbrk(out, "\r\n");
        if (nl) *nl = 0;
        if (out[0]) break;
        out[0] = 0;
    }
    fclose(f);
}

/* resolve the launcher component of a package -> "pkg/activity".
 * Two spellings are tried because `cmd package` / `pm` differ by version.
 * Only ever called from a child process (it pops a shell). */
static int resolve_component(const char *pkg, char *out, size_t n) {
    out[0] = 0;
    const char *tpl[2] = {
        "/system/bin/cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER %s 2>/dev/null | /system/bin/tail -1",
        "/system/bin/pm resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER %s 2>/dev/null | /system/bin/tail -1"
    };
    for (int i = 0; i < 2 && !out[0]; i++) {
        char rcmd[512];
        snprintf(rcmd, sizeof(rcmd), tpl[i], pkg);
        FILE *pr = popen(rcmd, "r");
        if (!pr) continue;
        char line[512] = {0};
        int got = fgets(line, sizeof(line), pr) != NULL;
        pclose(pr);
        if (!got) continue;
        /* 鏈夌殑鐗堟湰浼氬甫 "priority=0 ..." 鍓嶇紑锛屽彇鏈€鍚庝竴涓惈 '/' 鐨?token */
        char *best = NULL;
        for (char *t = strtok(line, " \t\r\n"); t; t = strtok(NULL, " \t\r\n")) {
            if (strchr(t, '/')) best = t;
        }
        if (best) snprintf(out, n, "%s", best);
    }
    return out[0] ? 1 : 0;
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
            if (n >= 2) {
                /* 灞呬腑瑕?280ms 鐨勬湁鐣屾杩涳紝鏀惧埌瀛愯繘绋嬮噷鍋氾細鍛戒护寰幆涓嶈鍗′綇銆?                 * 瀛愯繘绋嬬户鎵垮悓涓€涓?uinput 榧犳爣 fd锛孯EL 浜嬩欢椤哄簭涓嶅彉銆?*/
                if (fork() == 0) {
                    child_quiet_stdio();
                    cmd_center(w, h, park, rot);
                    _exit(0);
                }
            }
            break;
        }
        case 'T': {
            if (fork() == 0) {
                child_quiet_stdio();
                cmd_alttab();
                _exit(0);
            }
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
            /* 鏉€鍓嶅彴锛氬寘鍚嶄緷娆″皾璇?dumpsys activity / dumpsys window / 缂撳瓨锛?             * 鐒跺悗 am force-stop锛坒unctional锛? 鐩存帴 SIGKILL 鎵€鏈夎繘绋嬶紙鍏滃簳锛夈€?             * 涓や釜 dumpsys锛?00~300ms锛夐兘鍦ㄥ瓙杩涚▼閲岃窇锛屽懡浠ゅ惊鐜笉闃诲銆?*/
            if (fork() != 0) break;
            child_quiet_stdio();
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
            if (!pkg[0]) {
                /* 鏈€鍚庡厹搴曪細App 涓婃鏌ヨ鍒板苟缂撳瓨鍦?top.txt 閲岀殑鍓嶅彴鍖?*/
                top_cache_read(pkg, sizeof(pkg));
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
            _exit(0);
        }
        case '?':
            if (fork() == 0) {
                child_quiet_stdio();
                cmd_selftest();
                _exit(0);
            }
            break;
        case 'p': {
            /* 妯℃嫙鐢垫簮閿細浼樺厛鐢ㄦ垜浠嚜宸辫櫄鎷熼敭鐩樼殑 KEY_POWER锛堝唴鏍哥骇锛屼笉渚濊禆
             * SELinux/binder锛夛紝澶辫触鍐嶉€€鍥?`input keyevent 26`銆?             * 閲婃斁璧颁富寰幆鐨勫欢鏃堕槦鍒楋細涓嶅啀 usleep(40ms) 鍗′綇鍛戒护寰幆銆?*/
            int ok = 0;
            if (g_kbd >= 0) {
                key_down(g_kbd, 116 /* KEY_POWER */);
                key_release_later(g_kbd, 116, 40);
                ok = 1;
                /* 鐢垫簮閿細缈昏浆灞忓箷鐘舵€侊細绔嬪埢璁╁敜閱掔紦瀛樺け鏁堬紝涓嬩竴娆?`u` 涓嶅啀璇垽 */
                wake_cache_write("Toggling");
            }
            if (!ok) {
                /* 鍏滃簳鏀惧埌瀛愯繘绋嬮噷璺戯細`input` 鍦ㄨ繖涓煙閲屽彲鑳介暱鏃堕棿涓嶈繑鍥烇紝
                 * 瀹冧細鍗′綇鏁翠釜鍛戒护寰幆锛堣〃鐜颁负鎸夐敭鍏ㄩ儴澶辩伒锛夈€?*/
                if (fork() == 0) {
                    devnull_redirect();
                    system("/system/bin/input keyevent 26");
                    _exit(0);
                }
            }
            out("POWER uinput=%d", ok);
            break;
        }
        case 'r': {
            int rot = 0;
            if (sscanf(line, "%d", &rot) == 1 && fork() == 0) {
                child_quiet_stdio();
                cmd_rotation(rot);
                _exit(0);
            }
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
            if (fork() == 0) {
                child_quiet_stdio();
                cmd_close_app();
                _exit(0);
            }
            break;
        case 'D': {
            int kd, kc;
            if (sscanf(line, "%d %d", &kd, &kc) == 2) {
                /* 浼樺厛鐢ㄦ垜浠嚜宸辩殑铏氭嫙閿洏娉ㄥ叆锛堝唴鏍哥骇锛岀ǔ瀹氾級锛?                 * `input keyevent` 鍦?ksu 鍩熼噷杩斿洖 512锛坋xit code 2锛夛紝浜嬩欢鏍规湰杩涗笉鍘伙紝
                 * HOME/BACK/闊抽噺/闈欓煶/濯掍綋閿叏閮芥槸"鏃ュ織鏈夈€佸疄闄呮病鍙嶅簲"銆?*/
                int lc = android_to_linux(kc);
                if (g_kbd >= 0 && lc >= 0) {
                    key_down(g_kbd, lc);
                    key_release_later(g_kbd, lc, 8);   /* 涓嶉樆濉炲懡浠ゅ惊鐜?*/
                    out("KEYUIN %d %d lcode=%d", kd, kc, lc);
                    /* 鐢垫簮閿紙26锛夌炕杞睆骞曠姸鎬侊細鍞ら啋缂撳瓨绔嬪嵆澶辨晥 */
                    if (kc == 26) wake_cache_write("Toggling");
                } else {
                    /* 娌℃槧灏勭殑閿墠閫€鍥?input锛堝瓙杩涚▼閲岃窇锛岄伩鍏嶅崱涓诲惊鐜級 */
                    if (fork() == 0) {
                        child_quiet_stdio();
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
            /* C <display> <androidKeyCode> ... : 缁勫悎閿紙Ctrl+Plus 绛夛級銆?             * 涓嶈蛋 `input keycombination`锛氬湪 root 涓婁笅鏂囬噷瀹冭繑鍥?512锛?             * 闇€瑕佹洿瀹界殑娉ㄥ叆鏉冮檺锛夛紝鑰?uinput 閿洏鏄繘绋嬪唴鎿嶄綔锛岀ǔ瀹氬彲鐢ㄣ€?*/
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
                /* 组合键的按下/间隔/释放有固定 sleep（8 键最坏 8×8+30+8×8≈158ms），
                 * 放子进程执行：与 O/P/Y/T 一致，命令循环不再被阻塞。
                 * 子进程继承同一个 uinput 键盘 fd，事件顺序不变。 */
                pid_t kc = fork();
                if (kc == 0) {
                    child_quiet_stdio();
                    int n = cmd_key_combo(codes, count);
                    out("KCOMBO %d %d emitted=%d", cd, count, n);
                    _exit(0);
                }
                if (kc < 0) out("ERR C fork: %s", strerror(errno));
            } else {
                out("ERR C no keys");
            }
            break;
        }
        case 't': {
            /* 褰撳墠鍓嶅彴鍖呭悕锛氭闈?娓告垙瑕佺敤 d-pad 杞彂锛岃€屼笉鏄Е鎽告粦鍔ㄣ€?             * 棣栨娌℃湁缂撳瓨鏃朵細鍚屾 dumpsys锛氭暣涓煡璇涪缁欏瓙杩涚▼锛屽惊鐜笉鍗°€?*/
            if (fork() == 0) {
                child_quiet_stdio();
                char pkg[160];
                top_package(pkg, sizeof(pkg));
                out("TOP %s", pkg);
                _exit(0);
            }
            break;
        }
        case 'h': {
            /* 闅愯棌绯荤粺榧犳爣鎸囬拡锛氶攢姣佽櫄鎷熼紶鏍囪澶囷紙鎸囬拡鍥炬爣闅忎箣娑堝け锛?*/
            if (g_mouse >= 0) {
                ioctl(g_mouse, UI_DEV_DESTROY);
                close(g_mouse);
                g_mouse = -1;
                out("POINTER off");
            }
            break;
        }
        case 'j': {
            /* 閲嶆柊鍒涘缓铏氭嫙榧犳爣锛堟寚閽堥噸鏂板嚭鐜帮級 */
            ensure_mouse();
            out("POINTER on");
            break;
        }
        case 'A': {
            /* A <dir> [hold]  dir: 1涓?2涓?3宸?4鍙?             * 鐢?App 鍐崇瓥鍚庡洖鍐欐柟鍚戯細璧拌櫄鎷熼敭鐩樼殑绠ご閿紙涓庢棫鐨勫師鐢熻浆鍙戠瓑浠凤紝
             * 绯荤粺浼氭妸瀹冨綋鎴?DPAD_*锛夛紝娌℃湁铏氭嫙閿洏鏃堕€€鍥?`input keyevent`銆?             * 閲婃斁鐢变富寰幆寤舵椂闃熷垪琛ュ彂锛屼笉鍐?usleep(45ms) 鍗′綇寰幆銆?*/
            int dir = 0, hold = 0;
            if (sscanf(line, "%d %d", &dir, &hold) < 1) { out("ERR A"); break; }
            int key = (dir == 1) ? 103 : (dir == 2) ? 108 : (dir == 3) ? 105 : 106;
            if (g_kbd >= 0) {
                key_down(g_kbd, key);
                if (hold) {
                    out("ARROW %d hold", dir);
                    break;
                }
                key_release_later(g_kbd, key, 45);
                out("ARROW %d", dir);
                break;
            }
            if (hold) {
                /* 娌℃湁铏氭嫙閿洏锛氭寜浣忚涔夌敤 keyevent 瀹炵幇涓嶄簡锛岄€€鍖栨垚涓€娆＄偣鍑?*/
            }
            int kc = (dir == 1) ? 19 : (dir == 2) ? 20 : (dir == 3) ? 21 : 22;
            if (fork() == 0) {
                devnull_redirect();
                char c2[96];
                snprintf(c2, sizeof(c2), "/system/bin/input keyevent %d", kc);
                system(c2);
                _exit(0);
            }
            out("ARROW %d fallback=key", dir);
            break;
        }
        case 'N': {
            /* 灞曞紑閫氱煡鏍忥細uinput 鐨?KEY_NOTIFICATION_CENTER 鍦ㄤ笁鏄熶笂涓嶇敓鏁堬紝
             * cmd statusbar 鍚屽煙娉ㄥ叆澶辫触锛屾墍浠ユ敼鎴?浠庨《閮ㄨ竟缂樹笅婊?鐨勭湡瀹炶Е鎽告墜鍔?             * 锛堝拰鐢ㄦ埛鎵嬫寚涓嬫媺閫氱煡鏍忓畬鍏ㄤ竴鏍凤級銆傝蛋涓茶鎵嬪娍闃熷垪锛屼笉浼氬拰婊氬姩/缈婚〉
             * 鎵嬪娍骞跺彂锛堝苟鍙戜細浜掔浉鍚炲苟鎴愪竴娆＄偣鍑伙級銆?*/
            int nw = g_disp_w > 0 ? g_disp_w : 2560;
            int nh = g_disp_h > 0 ? g_disp_h : 1600;
            swipe_req_t r;
            memset(&r, 0, sizeof(r));
            r.display = 0;
            r.x1 = nw / 2;
            r.y1 = 4;
            r.x2 = nw / 2;
            r.y2 = nh * 55 / 100;
            r.ms = 320;
            r.vertical = 1;
            r.is_notif = 1;
            r.tx1 = 0; r.tx2 = nw; r.ty1 = 0; r.ty2 = nh;
            swipe_submit(r, 0);
            break;
        }
        case 'W':
            /* SurfaceFlinger dump 200~600ms锛氬瓙杩涚▼鎵ц锛屽洖鍖?CURSOR */
            if (fork() == 0) {
                child_quiet_stdio();
                query_cursor();
                _exit(0);
            }
            break;
        case 'J': {
            int jd = 0, jw = 0, jh = 0;
            int n = sscanf(line, "%d %d %d", &jd, &jw, &jh);
            if (n >= 1 && jd > 0 && fork() == 0) {
                child_quiet_stdio();
                caption_fullscreen_click(jd, n >= 2 ? jw : 0, n >= 3 ? jh : 0);
                _exit(0);
            }
            break;
        }
        case 'F': {
            int fd = 0;
            char fcomp[192];
            if (sscanf(line, "%d %191s", &fd, fcomp) == 2 && fd > 0 && fork() == 0) {
                child_quiet_stdio();
                char cmd[420];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d --windowingMode 1 -n %s >/dev/null 2>&1",
                    fd, fcomp);
                int rc = system(cmd);
                out("FULLSCREEN %d %s rc=%d", fd, fcomp, rc);
                _exit(0);
            }
            break;
        }
        case 'X': {
            int xd = 0;
            char xc[96];
            if (sscanf(line, "%d %95s", &xd, xc) == 2 && fork() == 0) {
                child_quiet_stdio();
                injector_combo(xd, xc);
                _exit(0);
            }
            break;
        }
        case 'E': {
            int hd = 0;
            if (sscanf(line, "%d", &hd) == 1 && hd > 0 && fork() == 0) {
                child_quiet_stdio();
                char cmd[320];
                snprintf(cmd, sizeof(cmd),
                    "/system/bin/am start --display %d -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1",
                    hd);
                int rc = system(cmd);
                out("HOMEDEX %d rc=%d", hd, rc);
                _exit(0);
            }
            break;
        }
        case 'w': {
            /* w <pkg> : 鍚姩鐩爣搴旂敤锛堝悗鍙版湇鍔¤嚜宸?startActivity 浼氳绯荤粺鎷︼紝
             * 璧?root 鐨?am start 鎵嶅彲闈狅級銆?             * 涓昏矾寰勫浐瀹氫负銆宺esolve-activity 瑙ｆ瀽缁勪欢 + am start -n銆嶏細
             *   - `am start -p <pkg>` 瀵归儴鍒嗗簲鐢ㄤ細 unable to resolve Intent
             *     锛堝疄娴?PiliPlus锛夛紝鎵€浠?-p 鍙湪瑙ｆ瀽澶辫触鏃跺仛娆￠€夛紝骞舵墦
             *     fallback=pkg 鏍囪锛岀粷涓嶄綔涓轰富璺緞锛?             *   - 缁勪欢瑙ｆ瀽鍏堣瘯 `cmd package resolve-activity --brief`锛屽啀璇?             *     `pm resolve-activity --brief`锛?             *   - am start 鐨勮緭鍑轰細琚鏌ワ紙"Error:" 涔熷綋浣滃け璐ワ級锛屽け璐ユ墠 monkey 鍏滃簳銆?*/
            char pkg3[192] = {0};
            if (sscanf(line, "%191s", pkg3) == 1 && pkg3[0]) {
                pid_t ch = fork();
                if (ch == 0) {
                    child_quiet_stdio();
                    char comp[256] = {0};
                    int resolved = resolve_component(pkg3, comp, sizeof(comp));
                    int rc = -1;
                    char firstline[192] = {0};
                    if (resolved) {
                        char cmd4[640];
                        char tmpout[80];
                        snprintf(tmpout, sizeof(tmpout), "/data/local/tmp/gpm_open_%d.out", (int)getpid());
                        snprintf(cmd4, sizeof(cmd4),
                                 "/system/bin/am start -W -n %s -f 0x10000000 --user 0 >%s 2>&1",
                                 comp, tmpout);
                        rc = system(cmd4);
                        read_first_line(tmpout, firstline, sizeof(firstline));
                        unlink(tmpout);
                        out("OPEN_APP %s via %s rc=%d out=%s", pkg3, comp, rc, firstline[0] ? firstline : "-");
                        if (strstr(firstline, "Error")) rc = rc ? rc : 1;
                    } else {
                        out("OPEN_APP %s resolve_failed=1", pkg3);
                    }
                    if (rc != 0) {
                        /* 娆￠€夛紙涓嶆槸涓昏矾寰勶級锛欼ntent + 鍖呭悕杩囨护 */
                        char cmd5[420];
                        snprintf(cmd5, sizeof(cmd5),
                                 "/system/bin/am start -a android.intent.action.MAIN "
                                 "-c android.intent.category.LAUNCHER -p %s >/dev/null 2>&1", pkg3);
                        rc = system(cmd5);
                        out("OPEN_APP %s fallback=pkg rc=%d", pkg3, rc);
                    }
                    if (rc != 0) {
                        /* 鏈€鍚庡厹搴曪細monkey 鍚姩锛堣€佸姙娉曪紝鍑犱箮鎬昏兘鎷夎捣涓荤晫闈級 */
                        char cmd6[420];
                        snprintf(cmd6, sizeof(cmd6),
                                 "/system/bin/monkey -p %s -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1", pkg3);
                        int rc2 = system(cmd6);
                        out("OPEN_APP %s monkey rc=%d", pkg3, rc2);
                    }
                    _exit(0);
                }
                out("OPEN_APP %s async", pkg3);
            }
            break;
        }
        case 'q': {
            /* q <w> <h> : 瑙︽懜闈㈠昂瀵革紙鍍忕礌 -> 瑙︽懜鍧愭爣锛?*/
            int tw = 0, th = 0;
            if (sscanf(line, "%d %d", &tw, &th) == 2 && tw > 0 && th > 0) {
                g_touch_w = tw;
                g_touch_h = th;
                out("TOUCH_SIZE %d %d", g_touch_w, g_touch_h);
            }
            break;
        }
        case 'k': {
            /* k <x> <y> <down> : 鍗曟寚瑙︽懜锛堢偣鍑?/ 闀挎寜锛?*/
            int tx = 0, ty = 0, dn = 0;
            if (sscanf(line, "%d %d %d", &tx, &ty, &dn) == 3) touch_single(tx, ty, dn);
            break;
        }
        case 'l': {
            /* l <dir> <x> <y> : 鍙屾寚缂╂斁锛宒ir 0=鍋滄 1=鏀惧ぇ -1=缂╁皬 */
            int dir = 0, px = 0, py = 0;
            if (sscanf(line, "%d %d %d", &dir, &px, &py) == 3) {
                if (dir == 0) pinch_stop();
                else pinch_start(dir, px, py);
            }
            break;
        }
        case 'g': {
            /* 澧炵泭鏍囧畾锛?             *   g                 鏌ヨ 鈫?GAIN center=鈥?ptr=鈥?             *   g ?               鍚屼笂锛堟樉寮忔煡璇級
             *   g <center>        璁剧疆灞呬腑澧炵泭锛堝悜鍚庡吋瀹规棫璋冪敤锛?             *   g <center> <ptr>  鍚屾椂璁剧疆 REL->px 瀹炴祴澧炵泭
             * ptr 澧炵泭鍦?center 鏈爣瀹氭椂浣滀负榛樿鍊硷紝鎵€浠ユ爣瀹氳繃鐨勫€间竴瀹氱敓鏁堛€?*/
            double g1 = 0, g2 = 0;
            int n = sscanf(line, "%lf %lf", &g1, &g2);
            if (n <= 0) {
                out("GAIN center=%.3f ptr=%.3f effective=%.3f", g_center_gain, g_pointer_gain,
                    effective_gain());
                break;
            }
            if (g1 == 0.0) g_center_gain = 0.0;        /* 0 = 鍥炶惤鍒板疄娴?ptr 澧炵泭 */
            else if (g1 > 0.2 && g1 < 20.0) g_center_gain = g1;
            if (n >= 2 && g2 > 0.2 && g2 < 20.0) g_pointer_gain = g2;
            out("GAIN center=%.3f ptr=%.3f effective=%.3f", g_center_gain, g_pointer_gain,
                effective_gain());
            break;
        }
        case 'u': {
            /* 鐐逛寒灞忓箷锛堟憞鏉嗗ぇ骞呯Щ鍔ㄦ椂鐢卞簲鐢ㄨ皟鐢級銆傚凡浜椂闆舵敞鍏ャ€?*/
            cmd_wake_screen();
            break;
        }
        case 'c': {
            /* 鐪熷疄鍏夋爣浣嶇疆锛堥棴鐜眳涓敤锛夛細瀛愯繘绋嬫煡璇紝鍥炲寘 CURSOR x y */
            cmd_cursor_query();
            break;
        }
        case 'P': {
            /* P <x> <y> <maxX> <maxY> : 鎶婂厜鏍囨斁鍒扮粷瀵瑰潗鏍?             * 锛堢┖闂查殣钘忎細閿€姣侀紶鏍囪澶囷紝閲嶅缓鍚庣敤杩欐潯鎶婂厜鏍囨斁鍥?涓婃鐨勪綅缃?锛夈€?             * 鏈夌晫姝ヨ繘瑕?~280ms锛屾斁瀛愯繘绋嬶細涓诲惊鐜笉琚崱浣忋€?*/
            int px = 0, py = 0, pw = 0, ph = 0;
            int pn = sscanf(line, "%d %d %d %d", &px, &py, &pw, &ph);
            if (pn >= 2 && fork() == 0) {
                child_quiet_stdio();
                if (pw <= 0) pw = 2560;
                if (ph <= 0) ph = 1600;
                pointer_goto(px, py, pw, ph);
                out("POSPTR %d,%d", px, py);
                _exit(0);
            }
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
            /* 姣?2s 鐢ㄧ湡瀹?task 杈圭晫瑕嗙洊缂撳瓨锛氳鍐欏潖鐨?bounds 鏈€澶?2s 灏辫绾犳 */
            if (g_bounds_last_display >= 0)
                bounds_refresh_request(g_bounds_last_display, g_bounds_last_w, g_bounds_last_h, 1);  /* 周期刷新：force */
        }
        /* 闈為樆濉炴敹灏撅細鍒版湡鎸夐敭閲婃斁 / 鎺掗槦鎵嬪娍鍚姩 / 鍚庡彴缂撳瓨鍒锋柊 */
        long long next_key = key_release_due();
        gesture_poll();
        bounds_refresh_poll();
        wake_refresh_async();
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
        int timeout = g_pinch_dir != 0 ? 8 : gesture_poll_timeout();
        if (next_key >= 0 && next_key < timeout) timeout = next_key <= 0 ? 1 : (int)next_key;
        int rc = poll(pfd, n, timeout);
        reap_children();
        gesture_poll();
        key_release_due();
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
                    /* d-pad 涓€寰嬩笂鎶ョ粰 App锛堣蒋浠跺湪铏氭嫙鎺у埗鍣ㄥ眰涔嬩笂锛夛細
                     * App 鍐冲畾杩欐槸缁勫悎閿繕鏄櫘閫氭柟鍚戦敭锛屽啀鐢?H 鍛戒护鍥炲啓鍒拌櫄鎷熸墜鏌?*/
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
                    /* d-pad 閿悓鏍蜂氦缁?App 澶勭悊 */
                    out("KEY %d %d %d %lld", g_devs[i].id, ev->code, ev->value, now_ms());
                }
            }
        }
    }

        ungrab_all();
        for (int i = 0; i < g_ndev; i++) close(g_devs[i].fd);
        g_ndev = 0;
        /* 浼氳瘽缁撴潫锛氱粷涓嶇暀涓嬫寜浣忕殑閿紝涔熶笉鎶婁笂涓€鏉′細璇濈殑鎺掗槦鎵嬪娍甯﹁繘涓嬩竴鏉?*/
        key_release_all();
        g_qn = 0;
        g_swipe_next_at_ms = 0;
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


