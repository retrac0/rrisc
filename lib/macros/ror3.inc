; ror3 reg -- rotate reg right by 3 bits (12-bit word)
%macro ror3 reg
        ror  reg, reg
        ror  reg, reg
        ror  reg, reg
%endm
