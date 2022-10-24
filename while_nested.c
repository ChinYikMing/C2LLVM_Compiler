#include <stdio.h>

int main(){
    int i = 0;
    int j = 0;
    int size;

    printf("Enter the size of the triangle(positive integer):\n");
    scanf("%d", &size);

    while(i < size){
        j = 0;
        while(j <= i){
            if(j == i){
                printf("*\n");
            } else {
                printf("*");
            }
            j = j + 1;
        }
        i = i + 1;
    }

    return 0;
}
