// Function call with 5 arguments: first 3 in registers, 4th and 5th on stack.
// sum = 1+2+3+4+5 = 15
// Expected: r2 = 15
int add5(int a, int b, int c, int d, int e) {
    return a + b + c + d + e;
}

int main() {
    return add5(1, 2, 3, 4, 5);
}
