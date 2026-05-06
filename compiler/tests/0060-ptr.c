// Pointer read/write through a global variable.
// Expected: r2 = 55 (0o67) at halt.
int g;

int main() {
    int *p = &g;
    *p = 55;
    return *p;
}
