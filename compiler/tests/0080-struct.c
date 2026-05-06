// Struct field access and pointer-to-struct.
// Expected: r2 = 7 (0o7) at halt.
struct Vec {
    int x;
    int y;
};

struct Vec v;

int sum_vec(struct Vec *p) {
    return p->x + p->y;
}

int main() {
    v.x = 3;
    v.y = 4;
    return sum_vec(&v);
}
