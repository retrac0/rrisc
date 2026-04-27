"""Bus and simulator verification tests."""
from sim import CPU, Bus, BusConflict, make_ram, make_rom, make_io_stub

def check(desc, got, expected):
    if got != expected:
        print(f"FAIL  {desc}: expected {expected:04o}, got {got:04o}")
        return False
    print(f"ok    {desc}")
    return True

def test_floating_read():
    cpu = CPU()
    check("unregistered addr floats high", cpu.rdmem(0o0200), 0o7777)

def test_ram():
    cpu = CPU()
    cpu.wrmem(0o0010, 0o1234)
    check("RAM write/read", cpu.rdmem(0o0010), 0o1234)

def test_ram_boundary():
    cpu = CPU()
    cpu.wrmem(0o0077, 0o4321)  # last RAM address
    check("RAM last word", cpu.rdmem(0o0077), 0o4321)
    # address just past RAM is unregistered
    check("past-RAM floats high", cpu.rdmem(0o0100), 0o7777)

def test_nop_preserves_T():
    cpu = CPU()
    cpu.T = 1
    cpu._ram_data[0] = 0o0000  # nop
    cpu.pc = 0
    cpu.step()
    check("nop preserves T", cpu.T, 1)

def test_rom_write_noop():
    cpu = CPU()
    cpu._rom_data[0] = 0o5555
    cpu.wrmem(0o1000, 0o2222)  # write to ROM via bus -- should be dropped
    check("ROM write no-op", cpu.rdmem(0o1000), 0o5555)

def test_rom_boundary():
    cpu = CPU()
    cpu._rom_data[1023] = 0o3333  # last ROM word
    check("ROM last word", cpu.rdmem(0o2777), 0o3333)
    check("past-ROM floats high", cpu.rdmem(0o3000), 0o7777)

def test_io_stub():
    cpu = CPU()
    check("IO stub base read", cpu.rdmem(0o7770), 0)
    check("IO stub last read", cpu.rdmem(0o7777), 0)
    cpu.wrmem(0o7770, 0o1234)  # write should not raise
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
    """Multiple write handlers at same address all receive the write."""
    received = []
    bus = Bus()
    bus.register_address(0o0050, None, lambda a, v: received.append(('A', v)))
    bus.register_address(0o0050, None, lambda a, v: received.append(('B', v)))
    bus.write(0o0050, 0o0777)
    assert received == [('A', 0o0777), ('B', 0o0777)], f"broadcast failed: {received}"
    print(f"ok    write broadcast to both handlers")

def test_partial_decode():
    """Partial address decoding: device responds to multiple addresses."""
    # Device ignores low 2 bits (responds to 4 addresses as if they're one)
    data = [0o6543]
    bus = Bus()
    for offset in range(4):
        bus.register_address(0o0060 + offset, lambda a, d=data: d[0], None)
    for offset in range(4):
        v = bus.read(0o0060 + offset)
        check(f"partial decode 0o{0o0060+offset:04o}", v, 0o6543)

def test_randomize():
    cpu = CPU()
    cpu._ram_data[:] = [0] * 64
    cpu.randomize()
    nonzero = sum(1 for v in cpu._ram_data if v != 0)
    assert nonzero > 0, "randomize left RAM all zeros"
    print(f"ok    randomize set {nonzero}/64 RAM words non-zero")
    # ROM should be untouched (still all zero)
    assert all(v == 0 for v in cpu._rom_data), "randomize touched ROM"
    print("ok    randomize left ROM untouched")

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
