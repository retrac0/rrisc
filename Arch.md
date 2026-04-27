
# RRISC Architecture Reference

12-bit RISC-like architecture, octal-oriented: each instruction word divides naturally
into four 3-bit octal digits.

## Registers

| Register | Value | Notes |
|----------|-------|-------|
| r0 | 0 | Hardwired zero. Reads always return 0; writes are silently ignored. |
| r1-r6 | -- | General purpose. |
| r7 | 0o7777 (-1) | Hardwired -1. `add rX, rX, r7` is the idiomatic decrement. |

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
| **R3** | op \| rd \| ra \| rb | add, sub, and, jalr, ror, rol, lwr, swr |
| **RI** | op \| rd \| imm[5:3] \| imm[2:0] | lw, sw, lui, addi, bz, bnz |

In RI format the 6-bit immediate occupies bits 5-0 (the ra and rb fields combined).

## Opcode Table

| Op | Binary | Mnemonic | Format |
|----|--------|----------|--------|
| 0 | 000 | **add** | R3 |
| 1 | 001 | **sub** | R3 |
| 2 | 010 | **sw** | RI |
| 3 | 011 | **lw** | RI |
| 4 | 100 | **lui** / **bf** | RI |
| 5 | 101 | **addi** / **bt** | RI |
| 6 | 110 | **and** | R3 |
| 7 | 111 | **spec** | R3 |

Encoding regularity: every op differs from its bit-2-complement by exactly 1 bit
(000<->100, 001<->101, 010<->110, 011<->111), and adjacent pairs (add/sub, sw/lw, lui/addi,
and/spec) also differ by 1 bit.

---

## ALU Instructions (R3 format)

### add -- Add  `(op=0, 0b000)`

```
add rd, ra, rb
```

```
Example: add r1, r2, r3
Bits:  000 001 010 011
Octal: 0   1   2   3  = 0o0123
```

`rd = ra + rb` (12-bit wrapped). T is not affected.

---

### sub -- Subtract  `(op=1, 0b001)`

```
sub rd, ra, rb
```

```
Example: sub r4, r5, r6
Bits:  001 100 101 110
Octal: 1   4   5   6  = 0o1456
```

`rd = ra - rb` (12-bit wrapped). **T = 1** if bit 12 of the full result is set, i.e. when
ra < rb unsigned (a borrow occurred). **T = 0** otherwise.

`sub r0, ra, rb` compares ra and rb without writing a result (r0 is hardwired 0),
giving a pure compare-and-branch idiom.

---

### and -- Bitwise AND  `(op=6, 0b110)`

```
and rd, ra, rb
```

```
Example: and r1, r2, r3
Bits:  110 001 010 011
Octal: 6   1   2   3  = 0o6123
```

`rd = ra & rb` (masked to 12 bits). T = 1 if the result is zero, 0 otherwise.
`and rd, ra, r0` gives 0.

---

## Page-Addressed Memory Instructions (RI format)

These instructions use the **rd field as a base/page register**, not a destination.
The effective address is formed by combining bits 11-6 of `reg[rd]` with the 6-bit
immediate as bits 5-0.  The data register is always **r1** (source for sw, destination for lw).

```
addr = (reg[rd] & 0o7700) | imm6
```

### lw -- Load Word  `(op=3, 0b011)`

```
lw rd, imm6
```

```
Example: lw r2, 5
Bits:  011 010 000 101
Octal: 3   2   0   5  = 0o3205
```

`r1 = mem[addr]` where `addr = (reg[rd] & 0o7700) | imm6`.

The rd field selects the page; imm6 is the offset within that 64-word page.
The loaded value always goes into **r1** regardless of rd.  T is not affected.

Common idiom -- access I/O page via r7 (hardwired 0o7777):
```asm
lw r7, 0   ; r1 = mem[0o7700]  (first I/O register)
```

---

### sw -- Store Word  `(op=2, 0b010)`

```
sw rd, imm6
```

```
Example: sw r2, 5
Bits:  010 010 000 101
Octal: 2   2   0   5  = 0o2205
```

`mem[addr] = r1` where `addr = (reg[rd] & 0o7700) | imm6`.

The value stored is always from **r1**.  T is not affected.

---

## Immediate Instructions (RI format)

### lui -- Load Upper Immediate  `(op=4, 0b100)`

```
lui rd, imm6        ; rd != r0
```

```
Example: lui r2, 3
Bits:  100 010 000 011
Octal: 4   2   0   3  = 0o4203
```

`rd = imm6 << 6`. Places the 6-bit immediate into bits 11-6 of rd and clears bits 5-0.
Used together with addi to load a full 12-bit constant in two instructions:

```asm
lui  r1, 0o37    ; r1 = 0o3700
addi r1, 0o56    ; r1 = 0o3756
```

rd=0 is forbidden for lui; that encoding is reserved for **bz**.

---

### addi -- Add Immediate  `(op=5, 0b101)`

```
addi rd, imm6       ; rd != r0
```

```
Example: addi r1, 5
Bits:  101 001 000 101
Octal: 5   1   0   5  = 0o5105
```

`rd = rd + sign_extend(imm6)`. The 6-bit immediate is sign-extended to 12 bits
(range -32..31 as signed, 0..63 as unsigned). T is not affected.

rd=0 is forbidden for addi; that encoding is reserved for **bnz**.

---

## Branch Instructions

Branches are encoded using lui/addi with rd=0 or rd=7, both of which are otherwise
write-no-ops (r0 is hardwired 0, r7 is hardwired -1).  The rd field selects the sign
of the offset: **rd=0 (`000`) gives 0..+63, rd=7 (`111`) gives -64..-1**.  The 6-bit
immediate is always unsigned.  Combined range: **-64..+63 words**.

The offset is PC-relative, applied from the address of the branch instruction itself.

Opcode space:
- `40xx` (op=4, rd=0): **bf**, offsets 0..+63
- `47xx` (op=4, rd=7): **bf**, offsets -64..-1
- `50xx` (op=5, rd=0): **bt**, offsets 0..+63
- `57xx` (op=5, rd=7): **bt**, offsets -64..-1

### bf -- Branch if False  `(op=4, 0b100, rd=0 or rd=7)`

```
bf offset           ; encoded as lui r0, offset   (offset >= 0)
                    ; encoded as lui r7, offset+64 (offset < 0)
```

```
Example: bf +3
Bits:  100 000 000 011
Octal: 4   0   0   3  = 0o4003

Example: bf -40 (decimal)
Bits:  100 111 011 000
Octal: 4   7   3   0  = 0o4730
```

If **T = 0**: `pc = pc + offset`. Otherwise execution falls through to pc+1.

---

### bt -- Branch if True  `(op=5, 0b101, rd=0 or rd=7)`

```
bt offset           ; encoded as addi r0, offset   (offset >= 0)
                    ; encoded as addi r7, offset+64 (offset < 0)
```

```
Example: bt +0
Bits:  101 000 000 000
Octal: 5   0   0   0  = 0o5000

Example: bt -1
Bits:  101 111 111 111
Octal: 5   7   7   7  = 0o5777
```

If **T != 0**: `pc = pc + offset`. Otherwise execution falls through to pc+1.

---

## Special Operations  `(op=7, 0b111)`

Op=7 uses the rb field as a sub-opcode to select the operation.

### jalr -- Jump and Link Register  `(op=7, rb=0)`

```
jalr rd, ra
```

```
Example: jalr r1, r2
Bits:  111 001 010 000
Octal: 7   1   2   0  = 0o7120
```

`rd = pc` (address of the next instruction); `pc = ra`. Used for subroutine calls
(save return address in rd) and computed jumps (set rd=r0 to discard return address).

---

### ror -- Rotate Right  `(op=7, rb=1)`

```
ror rd, ra
```

```
Example: ror r1, r2
Bits:  111 001 010 001
Octal: 7   1   2   1  = 0o7121
```

`rd = rotate_right(ra, 1)`. Bit 0 of ra is shifted out into T; bit 11 of rd is filled with
the old value of T. Enables multi-word right-shifts by chaining ror through T.

---

### rol -- Rotate Left  `(op=7, rb=2)`

```
rol rd, ra
```

```
Example: rol r1, r2
Bits:  111 001 010 010
Octal: 7   1   2   2  = 0o7122
```

`rd = rotate_left(ra, 1)`. Bit 11 of ra is shifted out into T; bit 0 of rd is filled with
the old value of T. Enables multi-word left-shifts by chaining rol through T.

---

### lwr -- Load Word Register-indirect  `(op=7, rb=3)`

```
lwr rd, ra
```

```
Example: lwr r1, r2
Bits:  111 001 010 011
Octal: 7   1   2   3  = 0o7123
```

`rd = mem[ra]`. Loads the 12-bit word at word-address ra into rd.
The address is masked to 12 bits. T is not affected.

---

### swr -- Store Word Register-indirect  `(op=7, rb=4)`

```
swr rd, ra
```

```
Example: swr r1, r2
Bits:  111 001 010 100
Octal: 7   1   2   4  = 0o7124
```

`mem[ra] = rd`. Stores rd to the 12-bit word at word-address ra.
The address is masked to 12 bits. T is not affected.

---

## Pseudo-Instructions and Special Encodings

| Encoding | Octal | Meaning |
|----------|-------|---------|
| `000 000 000 000` | `0o0000` | **nop** -- no operation (`add r0, r0, r0`); preserves T |
| `111 111 111 111` | `0o7777` | **halt** -- stop execution |

**nop** (`0o0000`) is `add r0, r0, r0`: r0 is hardwired 0 so both operands and the
destination are discarded, and T is preserved. This is a true unconditional no-operation.

### li -- Load Immediate (synthetic, 2 words)

```
li rd, imm          ; rd != r0
```

Loads any 12-bit immediate into rd. Expands to a `lui`/`addi` pair:

```asm
lui  rd, upper      ; rd = upper << 6
addi rd, lower      ; rd = rd + sign_extend(lower)
```

where `lower = imm & 0o77` and `upper` is adjusted for `addi`'s sign extension: if
bit 5 of `lower` is set, `addi` would subtract 64, so `upper` is incremented by 1
(mod 64) to compensate.

```asm
li r1, 0o1234   ; r1 = 0o1234  ->  lui r1, 0o12 ; addi r1, 0o34
li r1, 0o3777   ; r1 = 0o3777  ->  lui r1, 0o40 ; addi r1, 0o77  (upper adjusted)
```

Consumes two consecutive instruction words.

---

## T Flag

1-bit condition flag. T is the output of arithmetic and shift operations; pure data
movement and bitwise instructions preserve it.

- **sub** -- T = 1 on unsigned borrow (ra < rb). T = 0 otherwise.
- **and** -- T = 1 if the result is zero. T = 0 otherwise.
- **ror** -- T = the bit shifted out of bit 0 (old bit 0 of ra).
- **rol** -- T = the bit shifted out of bit 11 (old bit 11 of ra).

**Read by:**
- **bf / bt** -- branch on T=0 / T=1
- **ror / rol** -- old T feeds into the vacated bit of the rotated result

**Preserved by:** add, addi, lui, jalr, lw, sw, lwr, swr, nop, halt.

Design intent: because add preserves T, a carry computed by a sub comparison
survives across subsequent add operations, enabling multi-word arithmetic carry
chains without extra bookkeeping.

Typical patterns:
```asm
sub r0, r2, r5   ; compare: T=1 if r2 < r5 (discard result)
bt  less_than    ; branch if T=1

sub r0, r0, r3   ; zero test: T=1 iff r3 != 0
bf  is_zero      ; branch taken when r3 == 0

; multi-word add: (r3:r2) += (r5:r4)
add  r2, r2, r4        ; low word sum
sub  r0, r2, r4        ; T=1 if low sum overflowed (carry out)
add  r3, r3, r5        ; high word sum (T preserved)
bf   no_carry
addi r3, 1             ; apply carry
no_carry:
```

---

## Memory Model

- **Address space:** 4096 12-bit words (addresses 0o0000-0o7777).
- **Word-addressed:** lw/sw/lwr/swr operate on whole 12-bit words; there is no byte addressing.
- **Binary file format:** each word packed little-endian into 2 bytes
  (byte 0 = bits 7-0, byte 1 bits 3-0 = bits 11-8; upper 4 bits of byte 1 unused).
- All addresses are masked to 12 bits on access.
