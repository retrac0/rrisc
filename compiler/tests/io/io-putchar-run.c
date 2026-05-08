#include "io_include.h"

int main() {
  int i = 0;
  while (i < 10) {
    putchar('0' + i);
    i = i + 1;
  }
  putchar('\n');
  exit(0);
  return 0;
}
