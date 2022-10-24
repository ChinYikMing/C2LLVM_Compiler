#include <stdio.h>

int main(){
    int arr[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    int size = 10;

    int i = 0;
    while(i < size){
        if(i == 8){
            break;
        } else if(i == 5){
            i = i + 1;
            continue;
        } else {
            arr[i] = i + 1;
            printf("arr[%d]: %d\n", i, arr[i]);
            i = i + 1;
        }
    }

    return 0;
}
