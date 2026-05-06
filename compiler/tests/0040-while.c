// While loop: sum 1..n.
// Expected: r2 = 55 (0o67) at halt.
int sum(int n) {
    int s = 0;
    int i = 1;
    while (i <= n) {
        s = s + i;
        i = i + 1;
    }
    return s;
}

int main() {
    return sum(10);
}
