/* Minimal control-flow for SSA optimizer regression (no lib multiply calls). */
int main() {
    int x = 0;
    int i = 0;
    while (i < 4) {
        x = x + i;
        i = i + 1;
    }
    return x;
}
