// vgpad.c - create a virtual gamepad via /dev/uinput and emit events.
// build (WSL): aarch64-linux-gnu-gcc -O2 -static -o vgpad vgpad.c
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <linux/uinput.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <time.h>

static int fd = -1;

static void emit(int type, int code, int val) {
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type;
    ev.code = code;
    ev.value = val;
    if (write(fd, &ev, sizeof(ev)) < 0) perror("write");
}
static void syn(void) { emit(EV_SYN, SYN_REPORT, 0); }
static void sleep_ms(int ms) {
    struct timespec ts = { ms / 1000, (long)(ms % 1000) * 1000000L };
    nanosleep(&ts, NULL);
}

static void set_abs(int code, int min, int max) {
    struct uinput_abs_setup a;
    memset(&a, 0, sizeof(a));
    a.code = code;
    a.absinfo.minimum = min;
    a.absinfo.maximum = max;
    a.absinfo.fuzz = 0;
    a.absinfo.flat = 0;
    if (ioctl(fd, UI_SET_ABSBIT, code) < 0) perror("UI_SET_ABSBIT");
    if (ioctl(fd, UI_ABS_SETUP, &a) < 0) perror("UI_ABS_SETUP");
}

int main(int argc, char **argv) {
    fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) { perror("open /dev/uinput"); return 1; }

    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_EVBIT, EV_MSC);

    // buttons (so Android classifies it as GAMEPAD)
    int keys[] = { BTN_SOUTH, BTN_EAST, BTN_WEST, BTN_NORTH, BTN_TL, BTN_TR,
                   BTN_TL2, BTN_TR2, BTN_START, BTN_SELECT, BTN_MODE,
                   BTN_THUMBL, BTN_THUMBR,
                   BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT,
                   KEY_BACK, KEY_HOMEPAGE, KEY_RECORD };
    for (unsigned i = 0; i < sizeof(keys)/sizeof(keys[0]); i++)
        ioctl(fd, UI_SET_KEYBIT, keys[i]);

    set_abs(ABS_X, -32768, 32767);
    set_abs(ABS_Y, -32768, 32767);
    set_abs(ABS_Z, -32768, 32767);   // right stick X
    set_abs(ABS_RZ, -32768, 32767);  // right stick Y
    set_abs(ABS_RX, -32768, 32767);
    set_abs(ABS_RY, -32768, 32767);
    set_abs(ABS_HAT0X, -1, 1);
    set_abs(ABS_HAT0Y, -1, 1);
    set_abs(ABS_GAS, 0, 255);
    set_abs(ABS_BRAKE, 0, 255);

    struct uinput_setup us;
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_BLUETOOTH;
    us.id.vendor = 0x045e;
    us.id.product = 0x0b13;
    us.id.version = 0x0101;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "Virtual Test Gamepad");
    if (ioctl(fd, UI_DEV_SETUP, &us) < 0) { perror("UI_DEV_SETUP"); return 1; }
    if (ioctl(fd, UI_DEV_CREATE) < 0) { perror("UI_DEV_CREATE"); return 1; }
    fprintf(stderr, "virtual gamepad created\n");
    sleep_ms(900);  // let Android enumerate it

    if (argc < 2) {
        // default: wiggle left stick
        for (int i = 0; i < 6; i++) {
            emit(EV_ABS, ABS_X, 30000); syn(); sleep_ms(80);
            emit(EV_ABS, ABS_X, 0); syn(); sleep_ms(80);
        }
    } else if (!strcmp(argv[1], "stick")) {
        // vgpad stick <axis> <value> <ms>
        int axis = atoi(argv[2]);
        int val = atoi(argv[3]);
        int ms = argc > 4 ? atoi(argv[4]) : 1000;
        int pre = argc > 5 ? atoi(argv[5]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(ms);
        emit(EV_ABS, axis, 0); syn();
    } else if (!strcmp(argv[1], "hat")) {
        int hx = atoi(argv[2]);
        int hy = atoi(argv[3]);
        int ms = argc > 4 ? atoi(argv[4]) : 800;
        int pre = argc > 5 ? atoi(argv[5]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_ABS, ABS_HAT0X, hx);
        emit(EV_ABS, ABS_HAT0Y, hy);
        syn();
        sleep_ms(ms);
        emit(EV_ABS, ABS_HAT0X, 0);
        emit(EV_ABS, ABS_HAT0Y, 0);
        syn();
    } else if (!strcmp(argv[1], "key")) {
        int code = atoi(argv[2]);
        int ms = argc > 3 ? atoi(argv[3]) : 120;
        if (argc > 4) sleep_ms(atoi(argv[4]));
        emit(EV_KEY, code, 1); syn();
        sleep_ms(ms);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "hold")) {
        // vgpad hold <code> <ms>  : press and hold
        int code = atoi(argv[2]);
        int ms = argc > 3 ? atoi(argv[3]) : 2000;
        emit(EV_KEY, code, 1); syn();
        sleep_ms(ms);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "chatty")) {
        // vgpad chatty <code> <count> <intervalMs>
        int code = atoi(argv[2]);
        int count = argc > 3 ? atoi(argv[3]) : 8;
        int iv = argc > 4 ? atoi(argv[4]) : 500;
        for (int i = 0; i < count; i++) {
            emit(EV_KEY, code, 1); syn(); sleep_ms(60);
            emit(EV_KEY, code, 0); syn();
            sleep_ms(iv - 60);
        }    } else if (!strcmp(argv[1], "combo")) {
        // vgpad combo <k1> <k2> <holdMs>
        int k1 = atoi(argv[2]);
        int k2 = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 600;
        int pre = argc > 5 ? atoi(argv[5]) : 2600;
        if (pre > 0) sleep_ms(pre);   /* let the helper discover the device */
        emit(EV_KEY, k1, 1); syn();
        sleep_ms(300);
        emit(EV_KEY, k2, 1); syn();
        sleep_ms(hold);
        emit(EV_KEY, k2, 0); syn();
        sleep_ms(50);
        emit(EV_KEY, k1, 0); syn();
    } else if (!strcmp(argv[1], "double")) {
        // vgpad double <code> <pressMs> <gapMs> [pre]: two quick presses
        int code = atoi(argv[2]);
        int press = argc > 3 ? atoi(argv[3]) : 60;
        int gap = argc > 4 ? atoi(argv[4]) : 90;
        int pre = argc > 5 ? atoi(argv[5]) : 2600;
        if (pre > 0) sleep_ms(pre);   /* let the helper discover the device */
        emit(EV_KEY, code, 1); syn();
        sleep_ms(press);
        emit(EV_KEY, code, 0); syn();
        sleep_ms(gap);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(press);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "holdstick")) {
        // holdstick <keycode> <axis> <value> <holdMs> [pre]
        int code = atoi(argv[2]), axis = atoi(argv[3]), val = atoi(argv[4]);
        int ms = argc > 5 ? atoi(argv[5]) : 2000;
        int pre = argc > 6 ? atoi(argv[6]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(150);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(ms);
        emit(EV_ABS, axis, 0); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "keyvhat")) {
        // keyvhat <keycode> <hatY> <holdMs> [pre] : 先按键再推竖直方向（HAT0Y）
        int code = atoi(argv[2]), hy = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 400;
        int pre = argc > 5 ? atoi(argv[5]) : 2600;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(90);
        emit(EV_ABS, 17, hy); syn();
        sleep_ms(hold);
        emit(EV_ABS, 17, 0); syn();
        sleep_ms(60);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "keyhat")) {
        // keyhat <keycode> <hatY> <holdMs> [pre] : 先按键再推方向（测 X+↑ 这类组合）
        int code = atoi(argv[2]), hat = atoi(argv[3]);
        int hold = argc > 4 ? atoi(argv[4]) : 200;
        int pre = argc > 5 ? atoi(argv[5]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(90);
        emit(EV_ABS, 16, hat); syn();
        sleep_ms(hold);
        emit(EV_ABS, 16, 0); syn();
        sleep_ms(60);
        emit(EV_KEY, code, 0); syn();
    } else if (!strcmp(argv[1], "hatkey")) {
        // hatkey <hatValue> <keycode> [pre]
        int hat = atoi(argv[2]), code = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_ABS, 16, hat); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 1); syn();
        sleep_ms(80);
        emit(EV_KEY, code, 0); syn();
        emit(EV_ABS, 16, 0); syn();
    } else if (!strcmp(argv[1], "dblstick")) {
        // dblstick <keycode> <gapMs> <axis> <value> [pre]
        int code = atoi(argv[2]), gap = atoi(argv[3]);
        int axis = atoi(argv[4]), val = atoi(argv[5]);
        int pre = argc > 6 ? atoi(argv[6]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, code, 1); syn(); sleep_ms(40);
        emit(EV_KEY, code, 0); syn(); sleep_ms(gap);
        emit(EV_KEY, code, 1); syn(); sleep_ms(40);
        emit(EV_KEY, code, 0); syn();
        sleep_ms(60);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(300);
        emit(EV_ABS, axis, 0); syn();
    } else if (!strcmp(argv[1], "r3rstick")) {
        // r3rstick <axis> <value> [pre]: one R3 press, then move the right stick
        int axis = atoi(argv[2]), val = atoi(argv[3]);
        int pre = argc > 4 ? atoi(argv[4]) : 0;
        if (pre > 0) sleep_ms(pre);
        emit(EV_KEY, 318, 1); syn(); sleep_ms(40);
        emit(EV_KEY, 318, 0); syn();
        sleep_ms(50);
        emit(EV_ABS, axis, val); syn();
        sleep_ms(250);
        emit(EV_ABS, axis, 0); syn();
    } else if (!strcmp(argv[1], "seq")) {
        // stick then button
        for (int i = 0; i < 10; i++) {
            emit(EV_ABS, ABS_X, 20000); syn(); sleep_ms(60);
            emit(EV_ABS, ABS_X, 0); syn(); sleep_ms(60);
        }
        sleep_ms(200);
        emit(EV_KEY, BTN_SOUTH, 1); syn(); sleep_ms(120);
        emit(EV_KEY, BTN_SOUTH, 0); syn();
    }

    sleep_ms(150);
    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    fprintf(stderr, "done\n");
    return 0;
}

