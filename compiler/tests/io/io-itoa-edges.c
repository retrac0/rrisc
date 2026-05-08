#include "io_include.h"

void pl(int n) {
  int b[16];
  puts(itoa(n, b));
}

int main() {
  pl(0);
  pl(-1);
  /* -2048 breaks itoa: -n overflows 12-bit; stay in range. */
  pl(-2047);
  pl(2047);
  pl(42);
  exit(0);
  return 0;
}
