int mylen(int *s) {
    int n = 0;
    while (s[n]) n = n + 1;
    return n;
}
int main() { return mylen("hello"); }
