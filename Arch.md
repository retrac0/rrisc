
# RRISC Architecture Reference

12-bit RISC-like architecture, octal-oriented: each instruction word divides naturally
into four 3-bit octal digits.

## Registers

| Register | Value | Notes |
|----------|-------|-------|
| r0 | 0 | Hardwired zero. Reads always return 0; writes are silently ignored. |
| r1-r6 | -- | General purpose. |
| r7 | 0o7777 (-1) | Hardwired -1. |

All registers store 12-bit values; results are masked to 12 bits on write.

## Instruction Word Format

Every instruction is a 12-bit word divided into four 3-bit fields:

```
Bit:  11 10  9 | 8  7  6 | 5  4  3 | 2  1  0
       ---op--   ---rd--   ---ra--   ---rb--
```

Two formats share this layout:

| Format | Fields | Used by |
|--------|--------|---------|
| **R3** | op \| rd \| ra \| rb | and, sub, add, addc, jalr, ror, rol, lwr, swr |
| **RI** | op \| rd \| imm[5:3] \| imm[2:0] | lui, addi, subi, bf, bt |

In RI format the 6-bit immediate occupies bits 5-0 (the ra and rb fields combined).

## Opcode Table

| Op | Binary | Mnemonic | Format |
|----|--------|----------|--------|
| 0 | 000 | **and** | R3 |
| 1 | 001 | **sub** | R3 |
| 2 | 010 | **add** | R3 |
| 3 | 011 | **addc** | R3 |
| 4 | 100 | **lui** / **bf** | RI |
| 5 | 101 | **addi** / **bt** | RI |
| 6 | 110 | **subi** | RI |
| 7 | 111 | **spec** | R3 |

---

## ALU Instructions (R3 format)

### and -- Bitwise AND  `(op=0)`

```
and rd, ra, rb    ; rd = ra & rb
```

T is preserved. `and r0, r0, r0` = **nop** (0o0000).

---

### sub -- Subtract  `(op=1)`

```
sub rd, ra, rb    ; rd = ra - rb  (12-bit wrapped)
```

**T = 1** if borrow occurred (ra < rb unsigned). T = 0 otherwise.

`sub r0, ra, rb` compares without storing (r0 is hardwired 0), giving a pure
compare-and-branch idiom.

---

### add -- Add  `(op=2)`

```
add rd, ra, rb    ; rd = ra + rb  (12-bit wrapped, no carry-in)
```

**T = 1** if carry out of bit 11. T = 0 otherwise. T is not used as input.

---

### addc -- Add with Carry  `(op=3)`

```
addc rd, ra, rb   ; rd = ra + rb + T  (12-bit wrapped)
```

**T = 1** if carry out of bit 11. Chains after `add` or `sub` for multi-word arithmetic.

`addc r0, r0, r0` = **clrt** (0o3000): clears T without any other side-effect.

---

## Immediate Instructions (RI format)

### lui -- Load Upper Immediate  `(op=4)`

```
lui rd, imm6      ; rd = imm6 << 6   (rd != r0, rd != r7)
```

Places the 6-bit immediate into bits 11-6 of rd; bits 5-0 are cleared.
rd=0 and rd=7 are reserved for **bf**. T is preserved.

---

### addi -- Add Immediate  `(op=5)`

```
addi rd, imm6     ; rd = rd + imm6  (rd != r0, rd != r7)
```

Adds an **unsigned** 6-bit immediate (0..63) to rd. T is preserved.
rd=0 and rd=7 are reserved for **bt**.

Used with `lui` to load any 12-bit constant in two words:
```asm
lui  r1, upper    ; r1 = upper << 6
addi r1, lower    ; r1 = r1 + lower   (lower = 0..63)
```

---

### subi -- Subtract Immediate  `(op=6)`

```
subi rd, imm6     ; rd = rd - imm6
```

Subtracts an **unsigned** 6-bit immediate (0..63) from rd.
**T = 1** if borrow (rd < imm6 before subtraction). T = 0 otherwise.
rd=0 and rd=7 are forbidden.

---

## Branch Instructions

Branches are encoded using lui/addi with rd=0 or rd=7. The rd field selects the sign
of the offset: **rd=0 gives 0..+63, rd=7 gives -64..-1**. Combined range: **-64..+63 words**.

The offset is PC-relative from the branch instruction itself.

### bf -- Branch if False  `(op=4, rd=0 or rd=7)`

If **T = 0**: `pc = pc + offset`. Falls through when T = 1.

### bt -- Branch if True  `(op=5, rd=0 or rd=7)`

If **T != 0**: `pc = pc + offset`. Falls through when T = 0.

---

## Special Instructions  `(op=7, rb = sub-opcode)`

### jalr -- Jump and Link Register  `(rb=0)`

```
jalr rd, ra       ; rd = pc (next instruction); pc = ra
```

`jalr r5, r1` — call: save return address in r5, jump to r1.
`jalr r0, r5` — return: jump to r5, discard return address.

---

### ror -- Rotate Right  `(rb=1)`

```
ror rd, ra        ; rd = (T << 11) | (ra >> 1);  T = ra[0]
```

Bit 0 of ra shifts out into T; old T fills bit 11 of rd.
Chain `ror` to shift a multi-word value right through T.

---

### rol -- Rotate Left  `(rb=2)`

```
rol rd, ra        ; rd = (ra << 1) | T;  T = ra[11]
```

Bit 11 of ra shifts out into T; old T fills bit 0 of rd.
Chain `rol` to shift a multi-word value left through T.

---

### lwr -- Load Word (register-indirect)  `(rb=3)`

```
lwr rd, ra        ; rd = mem[ra]
```

T is preserved.

---

### swr -- Store Word (register-indirect)  `(rb=4)`

```
swr rd, ra        ; mem[ra] = rd
```

T is preserved.

---

## Pseudo-Instructions

| Mnemonic | Expansion | Notes |
|----------|-----------|-------|
| `nop` | `and r0, r0, r0` | no-op, T preserved |
| `clrt` | `addc r0, r0, r0` | clear T flag |
| `halt` | `0o7777` | stop execution |
| `li rd, imm` | `lui rd, upper; addi rd, lower` | load 12-bit constant (2 words) |
| `jmp label` | `li r4, label; jalr r0, r4` | unconditional jump (3 words) |
| `call label` | `li r4, label; jalr r5, r4` | call, return address in r5 (3 words) |

**li** encoding: `lower = imm & 0o77`, `upper = (imm >> 6) & 0o77`. Because `addi` is
unsigned (0..63), no sign-extension compensation is needed.

---

## T Flag Summary

| Instruction | T after |
|-------------|---------|
| sub rd, ra, rb | 1 if ra < rb (borrow) |
| add rd, ra, rb | 1 if carry out |
| addc rd, ra, rb | 1 if carry out (T used as carry-in) |
| subi rd, imm | 1 if borrow |
| rol rd, ra | old bit 11 of ra |
| ror rd, ra | old bit 0 of ra |
| and, lui, addi, jalr, lwr, swr | **preserved** |

---

## Multi-Word Arithmetic Patterns

### Multi-word add: (rhi:rlo) += (shi:slo)

```asm
clrt                    ; T = 0 (carry-in for first word)
addc rlo, rlo, slo      ; low word; T = carry out
addc rhi, rhi, shi      ; high word + carry; T = final carry
```

### Multi-word subtract: (rhi:rlo) -= (shi:slo)

Compute a − b = a + (~b) + 1 using two's complement. Set T=1 as the initial +1:

```asm
sub r0, r0, r7          ; 0 − (−1) overflows: T = 1
sub tmp_lo,  r7, slo    ; ~slo = r7 − slo  (T=0 after, r7 >= slo always)
sub tmp_hi,  r7, shi    ; ~shi
addc rlo, rlo, tmp_lo   ; rlo += ~slo + 1  (using T=1)
addc rhi, rhi, tmp_hi   ; rhi += ~shi + carry
```

### Multi-word left shift by 1

```asm
clrt                    ; T = 0 (fill bit)
rol rlo,  rlo           ; T = old bit 11 of rlo
rol rmid, rmid          ; T = old bit 11 of rmid
rol rhi,  rhi           ; T = old bit 11 of rhi  (overflow / carry-out bit)
```

### Multi-word right shift by 1 (logical)

```asm
clrt                    ; T = 0 (fill bit)
ror rhi,  rhi           ; T = old bit 0 of rhi
ror rmid, rmid          ; T = old bit 0 of rmid
ror rlo,  rlo           ; T = old bit 0 of rlo
```

### Multi-word right shift by 1 (arithmetic — sign-extend)

```asm
; Set T = sign bit of rhi before shifting:
and r1,   rhi,  r7      ; r1 = rhi
rol r1,   r1            ; T = bit 11 of rhi (sign)
ror rhi,  rhi           ; bit 11 filled with old T = sign
ror rmid, rmid
ror rlo,  rlo
```

---

## Memory Model

- **Address space:** 4096 12-bit words (addresses 0o0000–0o7777).
- **Word-addressed:** lwr/swr operate on whole 12-bit words; no byte addressing.
- **Default layout:** ROM at 0o1000 (1024 words), RAM at 0o0000 (64 words stack).
- **Binary format:** each word packed little-endian into 2 bytes
  (byte 0 = bits 7–0; byte 1 bits 3–0 = bits 11–8; upper 4 bits of byte 1 unused).

---

## Calling Convention (rcc compiler)

| Register | Role |
|----------|------|
| r0 | Zero (hardwired) |
| r1 | Scratch / address scratch |
| r2 | Arg 1 / return value |
| r3 | Arg 2 |
| r4 | Arg 3 |
| r5 | Link register (callee-saved) |
| r6 | Stack pointer (grows down) |
| r7 | −1 (hardwired) |

Arguments beyond 3 are pushed right-to-left and popped by the callee's epilogue.

---

## I/O Memory Map

| Address | Name | Direction | Description |
|---------|------|-----------|-------------|
| 0o7770 | TXRDY | read | 1 = UART transmit ready |
| 0o7771 | RXRDY | read | 1 = UART receive ready |
| 0o7772 | TXBUF | write | Write character to transmit |
| 0o7773 | RXBUF | read | Read received character |
