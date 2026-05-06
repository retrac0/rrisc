// Recursive Fibonacci.
// Expected: r2 = 21 (0o25) at halt.  fib(8) = 21.
int fib(int n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

int main() {
    return fib(8);
}
