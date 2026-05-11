#!/usr/bin/env python3
"""isa.py -- RRISC ISA constants, encoding, decoding, and disassembly."""

from dataclasses import dataclass
from typing import Literal

# Opcodes (3-bit, stored in bits 11:9)
# Bit 2 = 0: R3 register-register ops
# Bit 2 = 1: RI immediate/special ops
OP_AND  = 0   # rd=ra&rb; R3; preserves T; 0o0000=NOP; binary 000
OP_SUB  = 1   # rd=ra-rb; R3; T=borrow; binary 001
OP_ADD  = 2   # rd=ra+rb; R3; T=carry (no carry-in); binary 010
OP_ADDC = 3   # rd=ra+rb+T; R3; T=carry; 0o3000=CLRT; binary 011
OP_LUI  = 4   # rd=imm6<<6; also BF (rd=0 or rd=7); RI; binary 100
OP_ADDI = 5   # rd=rd+imm6 (unsigned 0..63); also BT; RI; binary 101
OP_SUBI = 6   # rd=rd-imm6 (unsigned 0..63); RI; T=borrow; binary 110
OP_SPEC = 7   # jalr/ror/rol/lwr/swr, distinguished by rb; binary 111

# Sub-opcodes for OP_SPEC (stored in bits 2:0)
RB_JALR = 0
RB_ROR  = 1
RB_ROL  = 2
RB_LWR  = 3
RB_SWR  = 4

WORD_MASK = 0o7777   # 12-bit mask
IMM6_MASK = 0o77     # 6-bit mask


@dataclass(frozen=True)
class Instruction:
    op:   int                  # 3-bit opcode
    rd:   int                  # 3-bit destination register
    ra:   int                  # bits 5:3 (R3 source A, or upper imm bits)
    rb:   int                  # bits 2:0 (R3 source B / SPEC sub-opcode)
    imm:  int                  # 6-bit raw immediate (= ra<<3|rb; meaningful for RI format)
    fmt:  Literal['R3', 'RI']  # format discriminator
    word: int                  # canonical 12-bit encoding


def sign_extend_imm(n: int) -> int:
    """Sign-extend a 6-bit immediate to a signed Python int."""
    n &= IMM6_MASK
    return n - 64 if (n & 32) else n


def branch_offset(rd: int, imm6: int) -> int:
    """Decode branch offset: rd=0 gives 0..63, rd=7 gives -64..-1."""
    return (imm6 & IMM6_MASK) - 64 if rd == 7 else (imm6 & IMM6_MASK)


def encode_r3(op: int, rd: int, ra: int, rb: int) -> int:
    """Pack R3 fields into a 12-bit word."""
    return ((op & 7) << 9) | ((rd & 7) << 6) | ((ra & 7) << 3) | (rb & 7)


def encode_ri(op: int, rd: int, imm6: int) -> int:
    """Pack RI fields into a 12-bit word."""
    return ((op & 7) << 9) | ((rd & 7) << 6) | (imm6 & IMM6_MASK)


def decode(word: int) -> Instruction:
    """Decode a 12-bit word into an Instruction."""
    word &= WORD_MASK
    op  = (word >> 9) & 7
    rd  = (word >> 6) & 7
    ra  = (word >> 3) & 7
    rb  =  word       & 7
    imm =  word       & IMM6_MASK
    fmt: Literal['R3', 'RI'] = 'RI' if op in (OP_LUI, OP_ADDI, OP_SUBI) else 'R3'
    return Instruction(op=op, rd=rd, ra=ra, rb=rb, imm=imm, fmt=fmt, word=word)


def disasm(instr: Instruction) -> str:
    """Return the canonical mnemonic string for an Instruction."""
    op, rd, ra, rb, imm, word = instr.op, instr.rd, instr.ra, instr.rb, instr.imm, instr.word

    if word == 0o0000:
        return "nop"
    elif word == 0o3000:
        return "clrt"
    elif word == 0o7777:
        return "halt"
    elif op == OP_AND:
        return f"and r{rd}, r{ra}, r{rb}"
    elif op == OP_SUB:
        return f"sub r{rd}, r{ra}, r{rb}"
    elif op == OP_ADD:
        return f"add r{rd}, r{ra}, r{rb}"
    elif op == OP_ADDC:
        return f"addc r{rd}, r{ra}, r{rb}"
    elif op == OP_LUI and (rd == 0 or rd == 7):
        return f"bf {branch_offset(rd, imm):+d}"
    elif op == OP_ADDI and (rd == 0 or rd == 7):
        return f"bt {branch_offset(rd, imm):+d}"
    elif op == OP_LUI:
        return f"lui r{rd}, {imm:02o}"
    elif op == OP_ADDI:
        return f"addi r{rd}, {imm}"
    elif op == OP_SUBI:
        return f"subi r{rd}, {imm}"
    elif op == OP_SPEC and rb == RB_JALR:
        return f"jalr r{rd}, r{ra}"
    elif op == OP_SPEC and rb == RB_ROR:
        return f"ror r{rd}, r{ra}"
    elif op == OP_SPEC and rb == RB_ROL:
        return f"rol r{rd}, r{ra}"
    elif op == OP_SPEC and rb == RB_LWR:
        return f"lwr r{rd}, r{ra}"
    elif op == OP_SPEC and rb == RB_SWR:
        return f"swr r{rd}, r{ra}"
    else:
        return "unknown"


def disasm_word(word: int) -> str:
    """Decode a 12-bit word and return its mnemonic string."""
    return disasm(decode(word))
