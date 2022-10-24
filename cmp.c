#include <stdio.h>

int main(){
    int a = 20, b = 20;

    printf("a = %d, b = %d\n", a, b);
    if(a > b){
        printf("%d > %d\n", a, b);
    } else if(a < b){
        printf("%d < %d\n", a, b);
    } else if(a == b){
        printf("%d == %d\n", b, a);
    }

    a = 30;
    b = 30;

    printf("\na = %d, b = %d\n", a, b);
    if(a >= b){
        printf("%d >= %d\n", a, b);
    } else if(a <= b){
        printf("%d <= %d\n", a, b);
    }

    a = 20;
    printf("\na = %d, b = %d\n", a, b);
    if(a != b){
        printf("%d != %d\n", a, b);
    }

    return 0;
}