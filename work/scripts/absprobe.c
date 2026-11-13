// quick probe: is a uinput ABS pointer treated as an absolute mouse by Android?
#include <fcntl.h>
#include <linux/uinput.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdlib.h>

static void emit(int fd, int type, int code, int val) {
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type;
    ev.code = code;
    ev.value = val;
    write(fd, &ev, sizeof(ev));
}

int main(int argc, char **argv) {
    int x = argc > 1 ? atoi(argv[1]) : 1280;
    int y = argc > 2 ? atoi(argv[2]) : 800;
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) { perror("open"); return 1; }
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    ioctl(fd, UI_SET_ABSBIT, ABS_X);
    ioctl(fd, UI_SET_ABSBIT, ABS_Y);
    struct uinput_abs_setup ax = {0}, ay = {0};
    ax.code = ABS_X;
    ax.absinfo.minimum = 0;
    ax.absinfo.maximum = 2559;
    ay.code = ABS_Y;
    ay.absinfo.minimum = 0;
    ay.absinfo.maximum = 1599;
    int xmax = argc > 3 ? atoi(argv[3]) : 2559;
    int ymax = argc > 4 ? atoi(argv[4]) : 1599;
    ax.absinfo.maximum = xmax;
    ay.absinfo.maximum = ymax;
    ioctl(fd, UI_ABS_SETUP, &ax);
    ioctl(fd, UI_ABS_SETUP, &ay);
    struct uinput_setup us = {0};
    us.id.bustype = BUS_USB;
    us.id.vendor = 0x1209;
    us.id.product = 0x0002;
    snprintf(us.name, UINPUT_MAX_NAME_SIZE, "DexPad AbsProbe");
    ioctl(fd, UI_DEV_SETUP, &us);
    ioctl(fd, UI_DEV_CREATE);
    usleep(600 * 1000);
    emit(fd, EV_ABS, ABS_X, x);
    emit(fd, EV_ABS, ABS_Y, y);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    usleep(300 * 1000);
    emit(fd, EV_KEY, BTN_LEFT, 1);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    usleep(80 * 1000);
    emit(fd, EV_KEY, BTN_LEFT, 0);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    usleep(300 * 1000);
    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
