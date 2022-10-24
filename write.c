#include <stdio.h>

int main(){
    int fd = open("testfile.txt", 1);

    char buf[] = "banana";
    int len = strlen(buf);
    write(fd, buf, len);
    close(fd);

    fd = open("testfile.txt", 0);
    char buf2[64];
    read(fd, buf2, len);
    printf("%s\n", buf2);

    close(fd);
    return 0;
}