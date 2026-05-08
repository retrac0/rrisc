#include "io_include.h"

int collatz_steps(int n) {
  int c = 0;
  while (n != 1) {
    if (n % 2 == 0) {
      n = n / 2;
    } else {
      n = 3 * n + 1;
    }
    c = c + 1;
  }
  return c;
}

int main() {
  int n = 2;
  while (n <= 18) {
    int buf[12];
    puts(itoa(collatz_steps(n), buf));
    n = n + 1;
  }
  exit(0);
  return 0;
}
