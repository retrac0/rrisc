; uart_rx.inc -- MMIO addresses for the UART receive side (see Arch.md I/O map)
%define RXRDY  0o7771           ; read: 1 = receive ready (a char is waiting)
%define RXBUF  0o7773           ; read: pop the next received char (low byte)
