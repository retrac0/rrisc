// Conditionals: compute absolute value.
// Expected: r2 = 10 (0o12) at halt.
int abs_val(int x) {
    if (x < 0) {
        return 0 - x;
    }
    return x;
}

int main() {
    int a = abs_val(0 - 7);   // 7
    int b = abs_val(3);       // 3
    return a + b;             // 10
}
