#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s <sock> <cmd... | ->\n", argv[0]);
        return 2;
    }
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { perror("socket"); return 1; }
    struct sockaddr_un a;
    memset(&a, 0, sizeof(a));
    a.sun_family = AF_UNIX;
    snprintf(a.sun_path, sizeof(a.sun_path), "%s", argv[1]);
    if (connect(fd, (struct sockaddr *)&a, sizeof(a)) < 0) { perror("connect"); return 1; }
    if (strcmp(argv[2], "-") == 0) {
        char buf[1024];
        ssize_t n;
        while ((n = read(STDIN_FILENO, buf, sizeof(buf))) > 0) {
            if (write(fd, buf, (size_t)n) != n) break;
        }
    } else {
        char cmd[1024];
        size_t n = 0;
        for (int i = 2; i < argc; i++) {
            size_t l = strlen(argv[i]);
            if (n + l + 2 >= sizeof(cmd)) break;
            memcpy(cmd + n, argv[i], l); n += l;
            cmd[n++] = ' ';
        }
        cmd[n++] = '\n';
        if (write(fd, cmd, n) != (ssize_t)n) { perror("write"); return 1; }
    }
    char buf[1024];
    ssize_t rd;
    while ((rd = read(fd, buf, sizeof(buf))) > 0) fwrite(buf, 1, (size_t)rd, stdout);
    fflush(stdout);
    return 0;
}
