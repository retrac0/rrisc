#include "io_include.h"

int main() {
    int buf[16];
    itoa(21 + 21, buf);
    puts(buf);
    exit(0);
    return 0;
}
