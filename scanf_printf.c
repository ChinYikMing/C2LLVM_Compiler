#include <stdio.h>

int main(){
    int a, b;
    char str[64];
    char c = 'c';
    printf("Enter two integer numbers:\n");
    scanf("%d %d", &a, &b);

    printf("Enter a string:\n");
    scanf("%s", str);

    printf("Enter a character:\n");
    scanf("\n%c", &c);

    printf("Integers: %d %d\n", a, b);
    printf("String: %s\n", str);
    printf("Character: %c\n", c);

    return 0;
}