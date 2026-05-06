// Nested function calls.
// Expected: r2 = 12 (0o14) at halt.
int double_it(int x) {
    return x + x;
}

int quadruple(int x) {
    return double_it(double_it(x));
}

int main() {
    return quadruple(3);
}
