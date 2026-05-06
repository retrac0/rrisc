// Pointer arithmetic: traverse global array via pointer increment.
// arr = {10, 20, 30, 40, 50}, sum = 150 (0o226)
// Expected: r2 = 150
int arr[5];

int main() {
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    int *p = arr;
    int sum = 0;
    int i = 0;
    while (i < 5) {
        sum = sum + *p;
        p = p + 1;
        i = i + 1;
    }
    return sum;
}
