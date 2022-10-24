#include <stdio.h>

int main(){
    char str[] = "apple";
    char str2[] = {'a', 'b', 'c'};
    int arr[] = {45, 46, 47};

    printf("str: %s, str2: %s\n", str, str2);
    printf("arr[0]: %d, arr[1]: %d, arr[2]: %d\n", arr[0], arr[1], arr[2]);

    return 0;
}