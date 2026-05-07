; uart_tx.inc -- MMIO addresses for the UART (see Arch.md I/O map)
%define TXRDY  0o7770           ; read: 1 = transmit ready
%define TXBUF  0o7772           ; write: TX data
