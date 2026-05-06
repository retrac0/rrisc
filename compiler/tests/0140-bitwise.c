// Bitwise operations on specific constants.
// a = 0xFF (255), b = 0xF0 (240)
// a & b = 0xF0 (240), a | b = 0xFF (255), a ^ b = 0x0F (15)
// Expected: r2 = 15 (a ^ b)
int main() {
    int a = 0xFF;
    int b = 0xF0;
    int c = a & b;
    int d = a | b;
    int e = a ^ b;
    return e;
}
