#ifndef GPMINPUT_H
#define GPMINPUT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <time.h>
#include <math.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <sys/ioctl.h>

/* logging: the engine side tails /data/adb/gpm/helper.log */
void out(const char *fmt, ...);

/* display helpers (display.c) */
void read_display_size(int display, int *w, int *h);

#endif
