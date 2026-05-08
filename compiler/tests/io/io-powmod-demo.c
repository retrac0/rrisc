#include "io_include.h"

int powmod(int a, int e, int m) {
  int r = 1;
  a = a % m;
  while (e > 0) {
    if (e % 2 == 1) {
      r = (r * a) % m;
    }
    a = (a * a) % m;
    e = e / 2;
  }
  return r;
}

int main() {
  int e = 0;
  while (e <= 16) {
    int buf[12];
    puts(itoa(powmod(3, e, 17), buf));
    e = e + 1;
  }
  exit(0);
  return 0;
}
