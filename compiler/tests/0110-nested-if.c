// Nested if/else with && and || conditions.
// Expected: r2 = 1
int main() {
    int a = 3;
    int b = 5;
    int result = 0;
    if (a < b && b > 2) {
        if (a == 3 || b == 10) {
            result = 1;
        }
    }
    if (a > b || b == 0) {
        result = 99;
    }
    return result;
}
