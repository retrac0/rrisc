// Local variables and integer arithmetic.
// Expected: r2 = 10 (0o12) at halt.
int main() {
    int a = 15;
    int b = 5;
    int c = a - b;      // 10
    int d = c + b;      // 15
    int e = d - b;      // 10
    return e;
}
