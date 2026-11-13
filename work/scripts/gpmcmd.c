// tiny client: send one line to the helper socket (for tests)
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc < 2) return 2;
    const char *path = "/data/data/com.dennis.dexpad/files/gpm.sock";
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { perror("socket"); return 1; }
    struct sockaddr_un sa;
    memset(&sa, 0, sizeof(sa));
    sa.sun_family = AF_UNIX;
    snprintf(sa.sun_path, sizeof(sa.sun_path), "%s", path);
    if (connect(fd, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
        perror("connect");
        return 1;
    }
    char line[256];
    snprintf(line, sizeof(line), "%s\n", argv[1]);
    ssize_t w = write(fd, line, strlen(line));
    (void)w;
    usleep(150 * 1000);
    close(fd);
    return 0;
}
