// Array indexing and global array.
// Expected: r2 = 6 (0o6) at halt.
int arr[5];

int main() {
    arr[0] = 1;
    arr[1] = 2;
    arr[2] = 3;
    arr[3] = 4;
    arr[4] = 5;
    return arr[1] + arr[3];   // 2 + 4 = 6
}
