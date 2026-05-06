// for loop with break and continue.
// Counts i=0..9, skipping i==3 (continue) and stopping at i==7 (break).
// count = 0,1,2, skip 3, 4,5,6, then break at 7 -> count = 6
// Expected: r2 = 6
int main() {
    int count = 0;
    int i;
    for (i = 0; i < 10; i = i + 1) {
        if (i == 3) continue;
        if (i == 7) break;
        count = count + 1;
    }
    return count;
}
