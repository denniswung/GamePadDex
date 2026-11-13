#include "gpminput.h"

/* display size of the DeX monitor */
void read_display_size(int display, int *w, int *h) {
    *w = 2560;
    *h = 1600;
    FILE *p = popen("dumpsys window displays 2>/dev/null", "r");
    if (!p) return;
    char buf[2048];
    int in = 0;
    while (fgets(buf, sizeof(buf), p)) {
        if (strstr(buf, "Display: mDisplayId=")) {
            in = atoi(strstr(buf, "Display: mDisplayId=") + strlen("Display: mDisplayId=")) == display;
            continue;
        }
        if (!in) continue;
        char *curp = strstr(buf, "cur=");
        if (!curp) curp = strstr(buf, "init=");
        if (!curp) continue;
        int ww = 0, hh = 0;
        if (sscanf(curp + 4, "%dx%d", &ww, &hh) == 2 && ww > 0 && hh > 0) {
            *w = ww;
            *h = hh;
            break;
        }
    }
    pclose(p);
}




