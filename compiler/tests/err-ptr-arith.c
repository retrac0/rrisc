int a;
int b;

int main() {
    int *p = &a;
    int *q = &b;
    return p + q;
}
