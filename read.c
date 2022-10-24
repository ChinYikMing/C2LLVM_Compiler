#include <stdio.h>

int main(){
    int fd = open("testfile.txt", 0);

    char buf[64];
    read(fd, buf, 64);
    printf("buf: %s\n", buf);

    close(fd);
    return 0;
}