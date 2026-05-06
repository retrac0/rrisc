// Nested while loops with inner break.
// Inner loop counts j=0,1,2 then breaks; outer runs 5 times.
// Expected: r2 = 15 (0o017) — 5 * 3
int main() {
    int x = 0;
    int i = 0;
    while (i < 5) {
        int j = 0;
        while (j < 5) {
            if (j == 3) break;
            x = x + 1;
            j = j + 1;
        }
        i = i + 1;
    }
    return x;
}
