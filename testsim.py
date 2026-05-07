"""Bus and simulator verification tests."""
from sim import CPU, Bus, BusConflict, DEFAULT_BANK_SPECS, parse_mem_spec


def _first_ram(cpu):
    return next(b for b in cpu._banks if b.type == "ram")


def check(desc, got, expected):
    if got != expected:
        print(f"FAIL  {desc}: expected {expected:04o}, got {got:04o}")
        return False
    print(f"ok    {desc}")
    return True


def test_floating_read():
    cpu = CPU()
    # Mid-RAM is backed; high UART window is unregistered without --terminal.
    check("unregistered addr floats high", cpu.rdmem(0o7775), 0o7777)


def test_ram():
    cpu = CPU()
    cpu.wrmem(0o0010, 0o1234)
    check("RAM write/read", cpu.rdmem(0o0010), 0o1234)


def test_ram_boundary():
    cpu = CPU()
    check("RAM last word addr", DEFAULT_BANK_SPECS[0][1] + DEFAULT_BANK_SPECS[0][2] - 1, 0o7767)
    cpu.wrmem(0o7767, 0o4321)
    check("RAM last word", cpu.rdmem(0o7767), 0o4321)
    check("past-RAM floats high", cpu.rdmem(0o7770), 0o7777)


def test_rom_write_noop():
    specs = [("ram", 0o0000, 0o0100), ("rom", 0o1000, 0o2000)]
    cpu = CPU([parse_mem_spec(f"{t}:{b}:{s}") for t, b, s in specs])
    rom = next(b for b in cpu._banks if b.type == "rom")
    rom.data[0] = 0o5555
    cpu.wrmem(0o1000, 0o2222)
    check("ROM write no-op", cpu.rdmem(0o1000), 0o5555)


def test_rom_boundary():
    specs = [("ram", 0o0000, 0o0100), ("rom", 0o1000, 0o2000)]
    cpu = CPU([parse_mem_spec(f"{t}:{b}:{s}") for t, b, s in specs])
    rom = next(b for b in cpu._banks if b.type == "rom")
    rom.data[1023] = 0o3333
    check("ROM last word", cpu.rdmem(0o2777), 0o3333)
    check("past-ROM floats high", cpu.rdmem(0o3000), 0o7777)


def test_io_stub():
    specs = [("ram", 0o0000, 0o7770), ("io", 0o7770, 8)]
    cpu = CPU([parse_mem_spec(f"{t}:{b}:{s}") for t, b, s in specs])
    check("IO stub base read", cpu.rdmem(0o7770), 0)
    check("IO stub last read", cpu.rdmem(0o7777), 0)
    cpu.wrmem(0o7770, 0o1234)
    check("IO stub after write", cpu.rdmem(0o7770), 0)


def test_bus_conflict():
    bus = Bus()
    bus.register_address(0o0100, lambda a: 0o1111, None)
    bus.register_address(0o0100, lambda a: 0o2222, None)
    try:
        bus.read(0o0100)
        print("FAIL  BusConflict not raised")
    except BusConflict as e:
        print(f"ok    BusConflict at {e.addr:04o} with values {[f'{v:04o}' for v in e.values]}")


def test_open_collector_write_broadcast():
    received = []
    bus = Bus()
    bus.register_address(0o0050, None, lambda a, v: received.append(("A", v)))
    bus.register_address(0o0050, None, lambda a, v: received.append(("B", v)))
    bus.write(0o0050, 0o0777)
    assert received == [("A", 0o0777), ("B", 0o0777)], f"broadcast failed: {received}"
    print("ok    write broadcast to both handlers")


def test_partial_decode():
    data = [0o6543]
    bus = Bus()
    for offset in range(4):
        bus.register_address(0o0060 + offset, lambda a, d=data: d[0], None)
    for offset in range(4):
        v = bus.read(0o0060 + offset)
        check(f"partial decode 0o{0o0060 + offset:04o}", v, 0o6543)


def test_randomize():
    cpu = CPU()
    ram = _first_ram(cpu)
    ram.data[:] = [0] * len(ram.data)
    cpu.randomize()
    nonzero = sum(1 for v in ram.data if v != 0)
    assert nonzero > 0, "randomize left RAM all zeros"
    print(f"ok    randomize set {nonzero}/{len(ram.data)} RAM words non-zero")
    rom_banks = [b for b in cpu._banks if b.type == "rom"]
    if rom_banks:
        assert all(v == 0 for b in rom_banks for v in b.data), "randomize touched ROM"
        print("ok    randomize left ROM untouched")


def test_nop_preserves_T():
    cpu = CPU()
    ram = _first_ram(cpu)
    ram.data[0] = 0o0000
    cpu.T = 1
    cpu.pc = 0
    cpu.step()
    check("nop preserves T", cpu.T, 1)


if __name__ == "__main__":
    test_floating_read()
    test_ram()
    test_ram_boundary()
    test_rom_write_noop()
    test_rom_boundary()
    test_io_stub()
    test_nop_preserves_T()
    test_bus_conflict()
    test_open_collector_write_broadcast()
    test_partial_decode()
    test_randomize()
