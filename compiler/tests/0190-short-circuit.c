// Short-circuit evaluation: side effects must NOT occur when skipped.
// '0 && set_flag(1)' -> set_flag not called (false && anything).
// '1 || set_flag(0)' -> set_flag not called (true || anything).
// Expected: r2 = 0 (set_flag never called)
int side_effect_called = 0;

int set_flag(int val) {
    side_effect_called = 1;
    return val;
}

int main() {
    if (0 && set_flag(1)) {
        side_effect_called = 99;
    }
    if (1 || set_flag(0)) {
        side_effect_called = 0;
    }
    return side_effect_called;
}
