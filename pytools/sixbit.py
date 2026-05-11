"""sixbit.py -- RRISC SIXBIT character encoding.

RRISC SIXBIT is a 6-bit, uppercase-only character set.  The encoding is the
low 6 bits of the uppercase ASCII code point, with newlines mapped to 0o37:

  0o00        NUL  (padding / ignored)
  0o01-0o32   A-Z
  0o33-0o36   [ \\ ] ^
  0o37        newline  (\\n / \\r)
  0o40-0o77   space ! " # $ % & ' ( ) * + , - . / 0-9 : ; < = > ?

This is similar to DEC SIXBIT but with letters at the low end (1-26) instead
of the high end, and digits/punctuation in the upper half.
"""

# Decode table: index is 6-bit SIXBIT value, value is the host character.
_DECODE = [''] * 64
for _v in range(1, 31):          # 0o01-0o36: A-Z and [\]^
    _DECODE[_v] = chr(_v + 0x40)
_DECODE[0o37] = '\n'              # 0o37: newline
for _v in range(0o40, 0o100):    # 0o40-0o77: space through '?'
    _DECODE[_v] = chr(_v)

# Encode table: host character -> 6-bit SIXBIT value (None = unmappable).
_ENCODE: dict[str, int] = {}
for _v, _ch in enumerate(_DECODE):
    if _ch:
        _ENCODE[_ch] = _v
# Fold lowercase -> uppercase
for _c in 'abcdefghijklmnopqrstuvwxyz':
    _ENCODE[_c] = _ENCODE[_c.upper()]
# Carriage return -> newline
_ENCODE['\r'] = 0o37


def encode_sixbit(ch: str) -> 'int | None':
    """Encode a single host character to a 6-bit SIXBIT value.

    Returns None for characters that have no SIXBIT representation.
    """
    return _ENCODE.get(ch)


def decode_sixbit(v: int) -> str:
    """Decode a 6-bit SIXBIT value to a host character string.

    Returns an empty string for NUL (0).
    """
    return _DECODE[v & 0x3F]


if __name__ == '__main__':
    print('SIXBIT decode table:')
    for v in range(64):
        ch = _DECODE[v]
        display = repr(ch) if ch else "''"
        print(f'  0o{v:02o} ({v:2d})  {display}')

    print('\nRound-trip check (printable ASCII 0x20-0x5F):')
    fails = 0
    for code in range(0x20, 0x60):
        ch = chr(code)
        v = encode_sixbit(ch)
        if v is None:
            print(f'  {ch!r} -> unmappable')
            continue
        back = decode_sixbit(v)
        expected = ch.upper()
        if back != expected:
            print(f'  FAIL {ch!r} -> 0o{v:02o} -> {back!r} (expected {expected!r})')
            fails += 1
    if not fails:
        print('  all pass')
