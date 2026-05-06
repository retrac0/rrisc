// Compound assignment operators.
// x = 10, +=5=15, -=3=12, ^=3=15, <<=1=30, >>=1=15
// Expected: r2 = 15
int main() {
    int x = 10;
    x += 5;
    x -= 3;
    x ^= 3;
    x <<= 1;
    x >>= 1;
    return x;
}
