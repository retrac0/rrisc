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

The reader thread puts incoming characters into the RX queue.  When stdin is a
tty the terminal is placed in cbreak mode so characters are delivered one at a
time without waiting for a newline; the original settings are restored at exit.
"""

import atexit
import queue
import sys
import threading

from sixbit import encode_sixbit, decode_sixbit

_RX_DEPTH = 16


class Terminal:
    def __init__(self, translate=False, preload=None, read_stdin=True):
        self._rx: queue.Queue[int] = queue.Queue(maxsize=_RX_DEPTH)
        self._old_term = None
        self._translate = translate

        if preload:
            for b in preload:
                self._rx.put(b & 0xFF)

        if read_stdin:
            if sys.stdin.isatty():
                self._enter_cbreak()
            t = threading.Thread(target=self._reader, name='terminal-rx', daemon=True)
            t.start()

    # -- terminal mode --

    def _enter_cbreak(self):
        import termios, tty
        fd = sys.stdin.fileno()
        self._old_term = termios.tcgetattr(fd)
        tty.setcbreak(fd)
        atexit.register(self._restore_term)

    def _restore_term(self):
        if self._old_term is not None:
            import termios
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, self._old_term)
            self._old_term = None

    # -- input thread --

    def _reader(self):
        while True:
            try:
                ch = sys.stdin.read(1)
            except (OSError, ValueError):
                break
            if not ch:
                break
            if self._translate:
                v = encode_sixbit(ch)
                if v is None:
                    continue
            else:
                v = ord(ch) & 0xFF
            try:
                self._rx.put(v, timeout=1)
            except queue.Full:
                pass   # drop if RX FIFO overflows, just like real hardware

    # -- bus handlers --

    def _tx_ready(self, addr):
        return 1   # always ready

    def _rx_ready(self, addr):
        return 0 if self._rx.empty() else 1

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
        try:
            return self._rx.get_nowait()
        except queue.Empty:
            return 0

    # -- registration --

    def register(self, bus):
        """Attach all four UART registers to the bus."""
        bus.register_address(0o7770, self._tx_ready, None)
        bus.register_address(0o7771, self._rx_ready, None)
        bus.register_address(0o7772, None,           self._tx_write)
        bus.register_address(0o7773, self._rx_read,  None)
