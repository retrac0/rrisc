// bool type (alias for int), true/false literals.
// flag = true (1), other = false (0); only flag branch taken.
// Expected: r2 = 1
int main() {
    bool flag = true;
    bool other = false;
    int result = 0;
    if (flag) {
        result = 1;
    }
    if (other) {
        result = 99;
    }
    return result;
}
