// Unsigned comparison: 0xFFF (4095) > 1 is true unsigned, false signed.
// Verifies that unsigned type uses borrow-based comparison, not sign-biased.
// Expected: r2 = 1
int main() {
    unsigned a = 0xFFF;
    unsigned b = 1;
    int result = 0;
    if (a > b) {
        result = 1;
    }
    return result;
}
