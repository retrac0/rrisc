"""terminal.py -- RRISC UART terminal device for the simulator.

Hardware register map (all addresses octal):

  7770  TX RDY  (read)   0001 = ready to transmit, 0000 = busy
  7771  RX RDY  (read)   0001 = character waiting,  0000 = empty
  7772  TX BUF  (write)  write a character to send
  7773  RX BUF  (read)   read the next character

TX is always ready -- characters are written directly to stdout.
The receive queue holds up to 16 characters (matching a shallow hardware FIFO).

When translate=True (--translate flag), the terminal applies SIXBIT encoding:
TX values are decoded from 6-bit SIXBIT to ASCII before output, and RX bytes
are encoded from ASCII to SIXBIT before queuing.  When translate=False (the
default), the lower 8 bits of each word are passed directly as raw bytes,
allowing ASCII/unicode applications to use the full 8-bit character range.

The reader thread fills the RX FIFO.  For a tty we use cbreak mode and
os.read on a dup of stdin's fd (TextIOWrapper can line-buffer sys.stdin.read;
sharing the same fd with os.read can also reorder data relative to the
wrapper).  The dup is closed and tty settings restored at exit.
"""

import atexit
import os
import sys
import threading
from collections import deque

from sixbit import encode_sixbit, decode_sixbit

_RX_DEPTH = 16


class Terminal:
    def __init__(self, translate=False, preload=None, read_stdin=True):
        self._rx: deque[int] = deque()
        self._rx_lock = threading.Lock()
        self._old_term = None
        self._translate = translate
        self._stdin_read_fd: int | None = None

        if preload:
            with self._rx_lock:
                for b in preload:
                    if len(self._rx) >= _RX_DEPTH:
                        break
                    self._rx.append(b & 0xFF)

        if read_stdin:
            if sys.stdin.isatty():
                self._enter_cbreak()
                self._stdin_read_fd = os.dup(sys.stdin.fileno())
            t = threading.Thread(target=self._reader, name='terminal-rx', daemon=True)
            t.start()

    def _enter_cbreak(self):
        import termios, tty
        fd = sys.stdin.fileno()
        self._old_term = termios.tcgetattr(fd)
        tty.setcbreak(fd)
        atexit.register(self._restore_term)

    def _restore_term(self):
        if self._stdin_read_fd is not None:
            try:
                os.close(self._stdin_read_fd)
            except OSError:
                pass
            self._stdin_read_fd = None
        if self._old_term is not None:
            import termios
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, self._old_term)
            self._old_term = None

    def _reader(self):
        while True:
            try:
                if self._stdin_read_fd is not None:
                    data = os.read(self._stdin_read_fd, 1)
                    if not data:
                        break
                    b0 = data[0]
                    if self._translate:
                        ch = chr(b0)
                        v = encode_sixbit(ch)
                        if v is None:
                            continue
                    else:
                        v = b0 & 0xFF
                else:
                    ch = sys.stdin.read(1)
                    if not ch:
                        break
                    if self._translate:
                        v = encode_sixbit(ch)
                        if v is None:
                            continue
                    else:
                        v = ord(ch) & 0xFF
            except (OSError, ValueError):
                break
            with self._rx_lock:
                if len(self._rx) < _RX_DEPTH:
                    self._rx.append(v)

    def _tx_ready(self, addr):
        return 1

    def _rx_ready(self, addr):
        with self._rx_lock:
            return 1 if self._rx else 0

    def _tx_write(self, addr, val):
        if self._translate:
            ch = decode_sixbit(val & 0x3F)
            if not ch:
                return
        else:
            ch = chr(val & 0xFF)
        sys.stdout.write(ch)
        sys.stdout.flush()

    def _rx_read(self, addr):
        with self._rx_lock:
            if not self._rx:
                return 0
            return self._rx.popleft()

    def register(self, bus):
        bus.register_address(0o7770, self._tx_ready, None)
        bus.register_address(0o7771, self._rx_ready, None)
        bus.register_address(0o7772, None, self._tx_write)
        bus.register_address(0o7773, self._rx_read, None)
