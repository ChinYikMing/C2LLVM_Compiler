#include <stdio.h>

int main(){
    int a = 3, b = 5;

    printf("Before: a = %d, b = %d\n", a, b);
    printf("Compute: a = b + 2 * (100 - 1)\n");
    a = b + 2 * (100 - 1);
    printf("After: a = %d\n", a);

    printf("Before: a = %d\n", a);
    printf("Compute: a = (a + 60) * (a + 70)\n");
    a = (a + 60) * (a + 70);
    printf("After: a = %d\n", a);

    b = b + 10;
    printf("Before: a = %d, b = %d\n", a, b);
    printf("Compute: a = b * (25 + a) + 90 - a\n");
    a = b * (25 + a) + 90 - a;
    printf("After: a = %d\n", a);

    b = 3000;
    printf("Before: a = %d, b = %d\n", a, b);
    printf("Compute: a = (a / 100) * -1 + b\n");
    a = (a / 100) * -1 + b;
    printf("After: a = %d\n", a);

    return 0;
}