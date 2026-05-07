#!/bin/env python3

# sim.py

# 12-bit word RISC-like architecture with 8 general-purpose registers

import argparse
import random

from terminal import Terminal
from isa import (OP_ADDI, OP_LUI, OP_AND, OP_ADD, OP_ADDC, OP_SUB, OP_SUBI, OP_SPEC,
                 RB_JALR, RB_ROR, RB_ROL, RB_LWR, RB_SWR,
                 branch_offset, decode, disasm_word, WORD_MASK, IMM6_MASK)



class BusConflict(Exception):
    def __init__(self, addr, values):
        self.addr = addr
        self.values = values
        super().__init__(f"Bus conflict at {addr:04o}: drivers returned {values}")


class Bus:
    ADDR_MASK = WORD_MASK

    def __init__(self):
        # Each slot: list of (read_fn|None, write_fn|None) tuples.
        # read_fn(addr) -> int|None  (None = not responding / device not selected)
        # write_fn(addr, val) -> None
        self._handlers: list[list[tuple]] = [[] for _ in range(4096)]
        self.trace = False

    def register_address(self, addr, read_fn, write_fn):
        self._handlers[addr & self.ADDR_MASK].append((read_fn, write_fn))

    def register_range(self, start, end, read_fn, write_fn):
        """Register handler for [start, end) -- end is exclusive."""
        for addr in range(start & self.ADDR_MASK, end):
            self._handlers[addr & self.ADDR_MASK].append((read_fn, write_fn))

    def read(self, addr) -> int:
        addr &= self.ADDR_MASK
        responses = []
        for rfn, _ in self._handlers[addr]:
            if rfn is not None:
                v = rfn(addr)
                if v is not None:
                    responses.append(v & self.ADDR_MASK)
        if len(responses) == 0:
            result = 0o7777
            if self.trace:
                print(f"  bus rd {addr:04o} -> {result:04o} [float]")
            return result
        if self.trace:
            note = f"[{len(responses)} drivers]" if len(responses) > 1 else ""
            print(f"  bus rd {addr:04o} -> {responses[0]:04o} {note}".rstrip())
        if len(responses) == 1:
            return responses[0]
        raise BusConflict(addr, responses)

    def write(self, addr, val):
        addr &= self.ADDR_MASK
        val &= self.ADDR_MASK
        writers = [wfn for _, wfn in self._handlers[addr] if wfn is not None]
        for wfn in writers:
            wfn(addr, val)
        if self.trace:
            note = f"[{len(writers)} writers]" if len(writers) != 1 else ""
            print(f"  bus wr {addr:04o} <- {val:04o} {note}".rstrip())


def make_ram(base, size):
    """Create a RAM device. Returns (data, read_fn, write_fn); data is the live backing list."""
    data = [0] * size
    def read_fn(addr): return data[addr - base]
    def write_fn(addr, val): data[addr - base] = val & WORD_MASK
    return data, read_fn, write_fn


def make_rom(base, data):
    """Create a ROM device from data (taken by reference, not copied).
    write_fn is None -- bus writes to ROM are silently dropped.
    Modify data directly to initialize ROM content."""
    def read_fn(addr):
        offset = addr - base
        return data[offset] if 0 <= offset < len(data) else None
    return data, read_fn, None


def make_io_stub(base, size):
    """Placeholder IO device: reads return 0, writes are no-ops.
    Both fns are non-None so the bus treats the page as claimed (no floating)."""
    def read_fn(addr): return 0
    def write_fn(addr, val): pass
    return read_fn, write_fn


def _load_binary_into(filename, data, offset=0):
    """Load a packed 12-bit binary file into data list starting at offset."""
    with open(filename, "rb") as f:
        i = offset
        while i < len(data):
            b = f.read(2)
            if not b:
                break
            if len(b) < 2:
                b += b'\x00' * (2 - len(b))
            data[i] = (b[0] | ((b[1] & 0x0F) << 8)) & WORD_MASK
            i += 1


def _load_binary_into_bus(filename, cpu, addr):
    """Load a packed 12-bit binary file onto the bus starting at addr."""
    with open(filename, "rb") as f:
        a = addr & WORD_MASK
        while True:
            b = f.read(2)
            if not b:
                break
            if len(b) < 2:
                b += b'\x00' * (2 - len(b))
            cpu.wrmem(a, (b[0] | ((b[1] & 0x0F) << 8)) & WORD_MASK)
            a = (a + 1) & WORD_MASK


class MemBank:
    """A single address-space bank: ram, rom, or io."""
    __slots__ = ('type', 'base', 'size', 'data')
    def __init__(self, type_, base, size, data):
        self.type = type_
        self.base = base
        self.size = size
        self.data = data  # list of words for ram/rom; None for io


DEFAULT_BANK_SPECS = [('ram', 0o0000, 0o0100), ('rom', 0o1000, 0o2000)]


def parse_mem_spec(spec):
    """Parse 'TYPE:BASE:SIZE' into (type, base, size). BASE and SIZE accept 0o-prefixed octal."""
    parts = spec.split(':')
    if len(parts) != 3:
        raise ValueError(f"--mem requires TYPE:BASE:SIZE, got: {spec!r}")
    type_ = parts[0].lower()
    if type_ not in ('ram', 'rom', 'io'):
        raise ValueError(f"unknown bank type: {type_!r}")
    return type_, int(parts[1], 0), int(parts[2], 0)


def build_banks(specs):
    """Create MemBank objects (data filled later by build_bus_from_banks)."""
    return [MemBank(type_, base, size, None) for type_, base, size in specs]


def build_bus_from_banks(banks):
    """Register all banks on a fresh Bus; fills bank.data for ram/rom banks."""
    bus = Bus()
    for bank in banks:
        if bank.type == 'ram':
            data, r, w = make_ram(bank.base, bank.size)
            bank.data = data
            bus.register_range(bank.base, bank.base + bank.size, r, w)
        elif bank.type == 'rom':
            bank.data = [0] * bank.size
            _, r, _ = make_rom(bank.base, bank.data)
            bus.register_range(bank.base, bank.base + bank.size, r, None)
        elif bank.type == 'io':
            r, w = make_io_stub(bank.base, bank.size)
            bus.register_range(bank.base, bank.base + bank.size, r, w)
    return bus


def load_binary(filename, mem):
    # stored little endian, 12 bit words packed into 2 bytes; overlays onto mem
    with open(filename, "rb") as f:
        addr = 0
        while True:
            bytes_read = f.read(2)
            if not bytes_read:
                break
            if len(bytes_read) < 2:
                bytes_read += b'\x00' * (2 - len(bytes_read))
            mem[addr] = (bytes_read[0] | ((bytes_read[1] & 0x0F) << 8)) & WORD_MASK
            addr += 1

class CPU:
    def __init__(self, specs=None):
        self.regfile = [0]*8  # 8 general purpose registers
        self.regfile[0] = 0  # r0 is always 0
        self.regfile[7] = 0o7777  # r7 is always -1
        self.T = 0  # T flag
        self.pc = 0  # program counter
        self.running = True
        self.trace = False
        self.instructions_retired = 0
        self.cycles = 0
        self._banks = build_banks(specs if specs is not None else DEFAULT_BANK_SPECS)
        self.bus = build_bus_from_banks(self._banks)

    def wrreg(self, rd, val):
        if rd != 0 and rd != 7:
            self.regfile[rd] = val & WORD_MASK

    def rdreg(self, rs):
        return self.regfile[rs]

    def rdmem(self, addr):
        return self.bus.read(addr)

    def wrmem(self, addr, val):
        self.bus.write(addr, val & WORD_MASK)

    def randomize(self):
        for bank in self._banks:
            if bank.type == 'ram' and bank.data is not None:
                for i in range(bank.size):
                    bank.data[i] = random.randint(0, 0o7777)
        for i in range(1, 7):  # r0 and r7 stay hardwired
            self.regfile[i] = random.randint(0, 0o7777)
        self.T = random.randint(0, 1)

    def load_mem(self, filename, addr=0):
        """Load binary as memory image -- file word N lands at mem[addr+N].
        Writes go directly to bank backing stores; addresses outside any bank
        are silently dropped."""
        addr &= WORD_MASK
        with open(filename, "rb") as f:
            i = 0
            while True:
                b = f.read(2)
                if not b:
                    break
                if len(b) < 2:
                    b += b'\x00' * (2 - len(b))
                word = (b[0] | ((b[1] & 0x0F) << 8)) & WORD_MASK
                a = (addr + i) & WORD_MASK
                for bank in self._banks:
                    if bank.base <= a < bank.base + bank.size and bank.data is not None:
                        bank.data[a - bank.base] = word
                        break
                i += 1

    def step(self):
        oldpc = self.pc
        ir = self.rdmem(oldpc)
        self.pc = (oldpc + 1) & WORD_MASK
        op = (ir >> 9) & 0o7
        rd = (ir >> 6) & 0o7
        ra = (ir >> 3) & 0o7
        rb = ir & 0o7
        imm = ir & IMM6_MASK
        note = ""

        if op == OP_AND:
            val = self.rdreg(ra) & self.rdreg(rb)
            self.wrreg(rd, val)
        elif op == OP_SUB:
            val = self.rdreg(ra) - self.rdreg(rb)
            self.wrreg(rd, val)
            self.T = 1 if (val & 0o10000) else 0
            note = f"T={self.T}"
        elif op == OP_ADD:
            val = self.rdreg(ra) + self.rdreg(rb)
            self.wrreg(rd, val)
            self.T = 1 if val > WORD_MASK else 0
            note = f"T={self.T}"
        elif op == OP_ADDC:
            val = self.rdreg(ra) + self.rdreg(rb) + self.T
            self.wrreg(rd, val)
            self.T = 1 if val > WORD_MASK else 0
            note = f"T={self.T}"
        elif op == OP_LUI and (rd == 0 or rd == 7): # bf
            if self.T == 0:
                self.pc = (oldpc + branch_offset(rd, imm)) & WORD_MASK
                note = f"-> {self.pc:04o}"
            else:
                note = "not taken"
        elif op == OP_ADDI and (rd == 0 or rd == 7): # bt
            if self.T != 0:
                self.pc = (oldpc + branch_offset(rd, imm)) & WORD_MASK
                note = f"-> {self.pc:04o}"
            else:
                note = "not taken"
        elif op == OP_LUI:
            self.wrreg(rd, (imm << 6))
        elif op == OP_ADDI:
            val = self.rdreg(rd) + imm   # unsigned 0..63
            self.wrreg(rd, val)
        elif op == OP_SUBI:
            val = self.rdreg(rd) - imm   # unsigned 0..63
            self.wrreg(rd, val)
            self.T = 1 if (val & 0o10000) else 0
            note = f"T={self.T}"
        elif op == OP_SPEC and rb == RB_JALR:
            target = self.rdreg(ra)
            self.wrreg(rd, self.pc)
            self.pc = target
            note = f"-> {self.pc:04o}"
        elif op == OP_SPEC and rb == RB_ROR:
            val = self.rdreg(ra)
            new_t = val & 1
            val = (val >> 1) | (self.T << 11)
            self.T = new_t
            self.wrreg(rd, val)
            note = f"T={self.T}"
        elif op == OP_SPEC and rb == RB_ROL:
            val = self.rdreg(ra)
            new_t = (val >> 11) & 1
            val = ((val << 1) & WORD_MASK) | self.T
            self.T = new_t
            self.wrreg(rd, val)
            note = f"T={self.T}"
        elif op == OP_SPEC and rb == RB_LWR:
            self.wrreg(rd, self.rdmem(self.rdreg(ra)))
            note = "+2cyc"
        elif op == OP_SPEC and rb == RB_SWR:
            self.wrmem(self.rdreg(ra), self.rdreg(rd))
            note = "+2cyc"
        elif ir == 0o7777: # halt
            self.running = False
        else:
            note = "unknown"

        is_mem = op == OP_SPEC and rb in (RB_LWR, RB_SWR)
        if self.trace:
            print(f"{oldpc:04o}  {ir:04o}  {disasm_word(ir):<20}  {note}".rstrip())

        self.instructions_retired += 1
        self.cycles += 2 if is_mem else 1
    

def show_regs(cpu : CPU) -> str:
    res = ""
    for i in range(8):
        res += f"r{i}: {cpu.rdreg(i):04o} "
    return res

def show_state(cpu : CPU) -> str:
    res = f"T: {cpu.T} PC: {cpu.pc:04o} "
    res += show_regs(cpu)
    return res

def memory_dump(cpu : CPU, start: int, end: int) -> str:
    res = ""
    for addr in range(start, end):
        # print address on modulo 8 and values in sets of 8 per line
        if addr % 8 == 0:
            if addr != start:
                res += "\n"
            res += f"{addr:04o}: "
        res += f"{cpu.rdmem(addr):04o} "
    res += "\n"
    return res

def disasm_block(cpu : CPU, start: int, end: int) -> str:
    res = ""
    for addr in range(start, end):
        instr = cpu.rdmem(addr)
        res += f"{addr:04o}: {instr:04o}  {disasm_word(instr)}\n"
    return res


# translates ASCII to sixbit where top two bits are stripped and if the ascii value was > 0x40 (64) then 32 is subtracted
def encode_sixbit(c):
    oldc = c
    c = c.upper()
    if c == "\n":
        c = "_"
    v = ord(c) & 0x3F
    if v > 0x40:
        v -= 0x20

    print(f"encoding {oldc} {ord(oldc):02x} -> {c} {v:02o}")
    return v

def decode_sixbit(c):
    return None


def test_sixbit():
    test_str = " Hello, World!\n"
    encoded = [encode_sixbit(c) for c in test_str]
    print("Encoded sixbit values:")
    for c, v in zip(test_str, encoded):
        print(f"'{c}': {v:02o}")

def run(cpu, summary=False):
    while cpu.running:
        cpu.step()

        if hasattr(cpu, 'max_cycles') and cpu.max_cycles > 0 and cpu.cycles >= cpu.max_cycles:
            raise RuntimeError(f"maxcycle {cpu.max_cycles} reached")

    if cpu.trace or summary:
        print(show_state(cpu))
        print(f"Instructions retired: {cpu.instructions_retired} ({cpu.cycles} cycles)")

def main():
    parser = argparse.ArgumentParser(description='rr sim')
    parser.add_argument('binary_filename', type=str)
    parser.add_argument('--trace', action='store_true', help='enable instruction trace output')
    parser.add_argument('--bustrace', action='store_true', help='trace all memory bus reads and writes')
    parser.add_argument('--summary', action='store_true', help='print final machine state and instruction count')
    parser.add_argument('--randomize', action='store_true', help='randomize registers and RAM before loading program')
    parser.add_argument('--terminal', action='store_true', help='attach UART terminal device')
    parser.add_argument('--translate', action='store_true',
                        help='enable SIXBIT translation on the terminal (default: pass raw bytes)')
    parser.add_argument('--start', default='0', metavar='ADDR', help='start address in octal (default 0)')
    parser.add_argument('--maxcycle', type=int, default=0, metavar='N',
                        help='halt with error after N cycles')
    parser.add_argument('--mem', action='append', default=[], metavar='TYPE:BASE:SIZE',
                        help='add a memory bank (repeatable); TYPE=ram|rom|io, BASE and SIZE in decimal or 0o-octal')
    args = parser.parse_args()

    specs = [parse_mem_spec(s) for s in args.mem] if args.mem else DEFAULT_BANK_SPECS
    cpu = CPU(specs)

    cpu.trace = args.trace
    cpu.bus.trace = args.bustrace

    if args.terminal:
        Terminal(translate=args.translate).register(cpu.bus)

    if args.randomize:
        cpu.randomize()
    cpu.load_mem(args.binary_filename)
    cpu.pc = int(args.start, 8) & WORD_MASK
    cpu.max_cycles = args.maxcycle
    run(cpu, summary=args.summary)

if __name__ == "__main__":
    main()
