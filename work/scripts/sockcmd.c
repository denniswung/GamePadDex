/* sockcmd: send one line to a GamePadDex helper socket and print the reply.
 * usage: sockcmd <socket-path> <line...>
 * Non-blocking connect with 1.5s timeout (the app socket serves one client at a
 * time, so a busy helper must not hang the test). After sending, the write side
 * is shut down so the helper flushes and closes, then replies are echoed. */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>

static int connect_timeout(int fd, struct sockaddr_un *a) {
    int fl = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, fl | O_NONBLOCK);
    int rc = connect(fd, (struct sockaddr *)a, sizeof *a);
    if (rc < 0 && errno == EINPROGRESS) {
        struct pollfd p; p.fd = fd; p.events = POLLOUT; p.revents = 0;
        if (poll(&p, 1, 1500) == 0) { fprintf(stderr, "busy: helper has another client\n"); return 3; }
        int err = 0; socklen_t el = sizeof err;
        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &el) < 0 || err) {
            fprintf(stderr, "connect: %s\n", strerror(err ? err : errno)); return 1;
        }
        rc = 0;
    } else if (rc < 0) { perror("connect"); return 1; }
    fcntl(fd, F_SETFL, fl);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s <sock> <cmd...>\n", argv[0]); return 2; }
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { perror("socket"); return 1; }
    struct sockaddr_un a; memset(&a, 0, sizeof a);
    a.sun_family = AF_UNIX;
    snprintf(a.sun_path, sizeof a.sun_path, "%s", argv[1]);
    int rc = connect_timeout(fd, &a);
    if (rc) return rc;

    char buf[512]; int n = 0;
    for (int i = 2; i < argc; i++) {
        int w = snprintf(buf + n, sizeof buf - n, "%s%s", i > 2 ? " " : "", argv[i]);
        if (w < 0 || n + w >= (int)sizeof buf - 1) break;
        n += w;
    }
    n += snprintf(buf + n, sizeof buf - n, "\n");
    if (write(fd, buf, n) < 0) { perror("write"); return 1; }
    shutdown(fd, SHUT_WR);

    struct pollfd p; p.fd = fd; p.events = POLLIN; p.revents = 0;
    char out[4096];
    while (poll(&p, 1, 3000) > 0) {
        ssize_t r = read(fd, out, sizeof out);
        if (r <= 0) break;
        fwrite(out, 1, (size_t)r, stdout);
        p.revents = 0;
    }
    close(fd);
    return 0;
}
