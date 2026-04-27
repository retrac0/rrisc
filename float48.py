"""Python reference for the RRISC 48-bit float format and arithmetic.

Format (big-endian, 4 x 12-bit words):
  word 0: sign<<11 | biased_exp_11    bias = 1024
  word 1: sig bits 35..24   (bit 11 = leading 1 for normals; explicit, not implicit)
  word 2: sig bits 23..12
  word 3: sig bits 11..0

Classes:
  exp_raw = 0           -> +/-0       (sign preserved)
  exp_raw = 2047        -> +/-inf (sig=0) or NaN (sig!=0)
  exp_raw = 1..2046     -> normal, value = (-1)^s * sig * 2^(exp_raw - 1024 - 35)

The pack/unpack/from_float/to_float helpers generate expected bit patterns for
asm tests.  The fadd/fsub/fmul/fdiv bit-level models use only integer ops that
map closely to the RRISC ISA (multi-word add/sub, 1-bit shifts, conditional
branches) and are used to validate the algorithm before transliterating to
assembly.  None of this is ever executed on the RRISC itself.
"""

import math

BIAS = 1024
SIG_BITS = 36
LEAD_BIT = 1 << (SIG_BITS - 1)           # bit 35
SIG_MASK = (1 << SIG_BITS) - 1
EXP_MAX = 2047
EXP_INF = EXP_MAX
WORD_MASK = 0xFFF


def pack(sign, exp_raw, sig):
    w0 = ((sign & 1) << 11) | (exp_raw & 0x7FF)
    w1 = (sig >> 24) & 0xFFF
    w2 = (sig >> 12) & 0xFFF
    w3 = sig & 0xFFF
    return (w0, w1, w2, w3)


def unpack(words):
    w0, w1, w2, w3 = words
    sign = (w0 >> 11) & 1
    exp_raw = w0 & 0x7FF
    sig = (w1 << 24) | (w2 << 12) | w3
    return sign, exp_raw, sig


def classify(exp_raw, sig):
    if exp_raw == 0:
        return 'zero'
    if exp_raw == EXP_INF:
        return 'nan' if sig else 'inf'
    return 'normal'


def from_float(x: float):
    """Pack a Python float into our 48-bit format (lossy below precision)."""
    if math.isnan(x):
        return pack(0, EXP_INF, 1 << 10)
    if math.isinf(x):
        return pack(1 if x < 0 else 0, EXP_INF, 0)
    if x == 0.0:
        return pack(1 if math.copysign(1.0, x) < 0 else 0, 0, 0)
    sign = 1 if x < 0 else 0
    x = abs(x)
    # normalize: find e so that 2^(SIG_BITS-1) <= x*2^-e+SIG_BITS... easier via ldexp
    m, e2 = math.frexp(x)    # x = m * 2^e2, 0.5 <= m < 1
    # we want sig such that sig/2^SIG_BITS = m -> sig = m * 2^SIG_BITS (range [2^35, 2^36))
    sig = int(m * (1 << SIG_BITS))
    # exponent relation: value = sig * 2^(exp_raw - BIAS - 35)
    # x = m * 2^e2 = sig * 2^(e2 - SIG_BITS), so exp_raw - BIAS - 35 = e2 - SIG_BITS
    # exp_raw = e2 - SIG_BITS + BIAS + 35 = e2 + BIAS - 1
    exp_raw = e2 + BIAS - 1
    if exp_raw >= EXP_INF:
        return pack(sign, EXP_INF, 0)         # overflow -> inf
    if exp_raw <= 0:
        return pack(sign, 0, 0)               # underflow -> 0 (no subnormals)
    return pack(sign, exp_raw, sig & SIG_MASK)


def to_float(words):
    """Convert a 48-bit RRISC float to a native IEEE 754 double."""
    sign, exp_raw, sig = unpack(words)
    cls = classify(exp_raw, sig)
    if cls == 'zero':
        return -0.0 if sign else 0.0
    if cls == 'inf':
        return float('-inf') if sign else float('inf')
    if cls == 'nan':
        return float('nan')
    val = sig * 2.0 ** (exp_raw - BIAS - (SIG_BITS - 1))
    return -val if sign else val


def format_words(words):
    return ' '.join(f'{w:04o}' for w in words)


# =============================================================================
# Bit-level arithmetic model
# =============================================================================


def _special_addsub(sa, ea, siga, sb, eb, sigb):
    """Return packed result if a special case fires, else None."""
    ca, cb = classify(ea, siga), classify(eb, sigb)
    if ca == 'nan' or cb == 'nan':
        return pack(0, EXP_INF, LEAD_BIT)            # a quiet NaN
    if ca == 'inf' and cb == 'inf':
        return pack(sa, EXP_INF, 0) if sa == sb else pack(0, EXP_INF, LEAD_BIT)
    if ca == 'inf':
        return pack(sa, EXP_INF, 0)
    if cb == 'inf':
        return pack(sb, EXP_INF, 0)
    if ca == 'zero' and cb == 'zero':
        # -0 + -0 = -0, else +0
        return pack(sa & sb, 0, 0)
    if ca == 'zero':
        return pack(sb, eb, sigb)
    if cb == 'zero':
        return pack(sa, ea, siga)
    return None


def fadd_bits(a_words, b_words):
    sa, ea, siga = unpack(a_words)
    sb, eb, sigb = unpack(b_words)
    sp = _special_addsub(sa, ea, siga, sb, eb, sigb)
    if sp is not None:
        return sp

    # Ensure ea >= eb (swap if not)
    if ea < eb:
        sa, sb = sb, sa
        ea, eb = eb, ea
        siga, sigb = sigb, siga

    # Align: shift sigb right by (ea - eb).  If >= SIG_BITS, effectively zero.
    diff = ea - eb
    if diff >= SIG_BITS:
        sigb = 0
    else:
        sigb >>= diff

    if sa == sb:
        # Same sign: add magnitudes.
        sig = siga + sigb
        exp = ea
        # Overflow of bit 36 (leading bit ends up at bit 36): shift right 1, bump exp.
        if sig & (1 << SIG_BITS):
            sig >>= 1
            exp += 1
        result_sign = sa
    else:
        # Different signs: subtract.  |a| >= |b| after the swap + alignment.
        sig = siga - sigb
        exp = ea
        result_sign = sa
        if sig == 0:
            return pack(0, 0, 0)                     # exact cancellation
        # Normalize left until leading bit is at bit 35.
        while sig & LEAD_BIT == 0:
            sig <<= 1
            exp -= 1
            if exp <= 0:                             # underflow -> +/-0
                return pack(result_sign, 0, 0)

    if exp >= EXP_INF:
        return pack(result_sign, EXP_INF, 0)         # overflow -> inf
    if exp <= 0:
        return pack(result_sign, 0, 0)               # underflow -> 0
    return pack(result_sign, exp, sig & SIG_MASK)


def fsub_bits(a_words, b_words):
    w0, w1, w2, w3 = b_words
    return fadd_bits(a_words, (w0 ^ 0x800, w1, w2, w3))


def fmul_bits(a_words, b_words):
    sa, ea, siga = unpack(a_words)
    sb, eb, sigb = unpack(b_words)
    ca, cb = classify(ea, siga), classify(eb, sigb)
    s = sa ^ sb
    if ca == 'nan' or cb == 'nan':
        return pack(0, EXP_INF, LEAD_BIT)
    if ca == 'zero' and cb == 'inf' or ca == 'inf' and cb == 'zero':
        return pack(0, EXP_INF, LEAD_BIT)            # 0*inf = NaN
    if ca == 'inf' or cb == 'inf':
        return pack(s, EXP_INF, 0)
    if ca == 'zero' or cb == 'zero':
        return pack(s, 0, 0)

    # Normal x normal.  Result sig = top SIG_BITS of (siga*sigb) shifted.
    prod = siga * sigb                               # up to 72 bits
    # siga, sigb in [2^35, 2^36); prod in [2^70, 2^72).
    # We want a 36-bit result with leading bit at position 35.
    # prod has leading bit at position 70 or 71.
    if prod & (1 << 71):
        sig = prod >> (SIG_BITS)                     # shift down 36; leading bit -> pos 35
        exp = ea + eb - BIAS + 1
    else:
        sig = prod >> (SIG_BITS - 1)                 # shift down 35
        exp = ea + eb - BIAS

    if exp >= EXP_INF:
        return pack(s, EXP_INF, 0)
    if exp <= 0:
        return pack(s, 0, 0)
    return pack(s, exp, sig & SIG_MASK)


def fdiv_bits(a_words, b_words):
    sa, ea, siga = unpack(a_words)
    sb, eb, sigb = unpack(b_words)
    ca, cb = classify(ea, siga), classify(eb, sigb)
    s = sa ^ sb
    if ca == 'nan' or cb == 'nan':
        return pack(0, EXP_INF, LEAD_BIT)
    if ca == 'zero' and cb == 'zero':
        return pack(0, EXP_INF, LEAD_BIT)
    if ca == 'inf' and cb == 'inf':
        return pack(0, EXP_INF, LEAD_BIT)
    if cb == 'zero':
        return pack(s, EXP_INF, 0)
    if ca == 'zero':
        return pack(s, 0, 0)
    if ca == 'inf':
        return pack(s, EXP_INF, 0)
    if cb == 'inf':
        return pack(s, 0, 0)

    # Normal / normal.  Compute siga / sigb with enough precision.
    # siga, sigb in [2^35, 2^36); siga/sigb in (0.5, 2).
    # Shift siga up by SIG_BITS so quotient is SIG_BITS+1 bits; take top SIG_BITS.
    num = siga << SIG_BITS                           # 72 bits
    q = num // sigb                                  # up to 37 bits
    # q in [2^35, 2^37).  Leading bit at 35 or 36.
    if q & (1 << SIG_BITS):
        q >>= 1
        exp = ea - eb + BIAS
    else:
        exp = ea - eb + BIAS - 1

    if exp >= EXP_INF:
        return pack(s, EXP_INF, 0)
    if exp <= 0:
        return pack(s, 0, 0)
    return pack(s, exp, q & SIG_MASK)


# =============================================================================
# Quick self-test
# =============================================================================

def _native(op, x, y):
    """Native IEEE 754 reference, with RRISC semantics for div-by-zero."""
    if op == 'add':
        return x + y
    if op == 'sub':
        return x - y
    if op == 'mul':
        # Python happily computes 0*inf -> raises; mimic IEEE: NaN
        if (x == 0.0 and math.isinf(y)) or (y == 0.0 and math.isinf(x)):
            return float('nan')
        return x * y
    if op == 'div':
        if y == 0.0:
            if x == 0.0 or math.isnan(x):
                return float('nan')
            if math.isinf(x):
                return float('nan')
            neg = (math.copysign(1.0, x) < 0) ^ (math.copysign(1.0, y) < 0)
            return float('-inf') if neg else float('inf')
        if math.isinf(x) and math.isinf(y):
            return float('nan')
        return x / y
    raise ValueError(op)


def _close(a, b, rel_tol=2**-30):
    """Compare with RRISC-grade precision; both NaN counts as equal."""
    if math.isnan(a) and math.isnan(b):
        return True
    if math.isnan(a) or math.isnan(b):
        return False
    if math.isinf(a) or math.isinf(b):
        return a == b
    if a == 0.0 and b == 0.0:
        return True
    if a == 0.0 or b == 0.0:
        return abs(a - b) < 1e-300
    return abs(a - b) / max(abs(a), abs(b)) <= rel_tol


if __name__ == '__main__':
    import sys

    if len(sys.argv) > 1:
        for arg in sys.argv[1:]:
            x = float(arg)
            w = from_float(x)
            print(f'{x!r:>20} -> {format_words(w)}  (round-trip: {to_float(w)!r})')
    else:
        cases = [
            # basic add/sub
            ('add',  1.0,        2.0),
            ('add',  3.14,       2.71),
            ('add',  100.5,      0.5),
            ('add',  1.0,       -1.0),
            ('add',  1e10,       1e-10),
            ('add', -2.5,        7.5),
            ('add', -3.14,      -2.71),
            ('sub',  5.0,        3.0),
            ('sub',  1.0,        2.0),
            ('sub',  1.0,        1.0),              # exact cancellation
            ('sub',  1e20,       1e20),
            ('sub',  1.0,        1e-20),
            ('sub', -5.0,       -3.0),
            # basic mul
            ('mul',  3.0,        4.0),
            ('mul',  0.5,        2.0),
            ('mul', -3.0,        4.0),
            ('mul', -3.0,       -4.0),
            ('mul',  1.5,        1.5),
            ('mul',  0.1,        0.1),
            ('mul',  1e50,       1e-50),
            # basic div
            ('div',  6.0,        2.0),
            ('div',  1.0,        3.0),
            ('div',  22.0,       7.0),
            ('div', -6.0,        2.0),
            ('div',  6.0,       -2.0),
            ('div',  1.0,        7.0),
            ('div',  1e50,       1e25),
            # overflow / underflow
            ('mul',  1e300,      1e300),            # -> +inf
            ('mul', -1e300,      1e300),            # -> -inf
            ('mul',  1e-200,     1e-200),           # -> 0
            ('div',  1e300,      1e-300),           # -> +inf
            ('div',  1e-300,     1e300),            # -> 0
            # signed zeros
            ('add',  0.0,        0.0),
            ('add', -0.0,        0.0),
            ('add', -0.0,       -0.0),
            ('mul', -0.0,        5.0),
            ('mul',  0.0,       -5.0),
            # infinities
            ('add',  float('inf'),  1.0),
            ('add',  float('inf'),  float('inf')),
            ('add',  float('inf'), -float('inf')),  # -> NaN
            ('sub',  float('inf'),  float('inf')),  # -> NaN
            ('mul',  float('inf'),  2.0),
            ('mul',  float('inf'),  0.0),           # -> NaN
            ('mul',  float('inf'), -float('inf')),
            ('div',  1.0,        0.0),              # -> +inf
            ('div', -1.0,        0.0),              # -> -inf
            ('div',  0.0,        0.0),              # -> NaN
            ('div',  float('inf'), float('inf')),   # -> NaN
            ('div',  float('inf'), 2.0),
            ('div',  2.0,        float('inf')),
            # NaN propagation
            ('add',  float('nan'), 1.0),
            ('sub',  1.0,        float('nan')),
            ('mul',  float('nan'), float('nan')),
            ('div',  float('nan'), 1.0),
        ]

        op_fn = {'add': fadd_bits, 'sub': fsub_bits, 'mul': fmul_bits, 'div': fdiv_bits}
        op_sym = {'add': '+', 'sub': '-', 'mul': '*', 'div': '/'}
        fails = 0
        for op, x, y in cases:
            a = from_float(x)
            b = from_float(y)
            r = op_fn[op](a, b)
            got = to_float(r)
            want = _native(op, to_float(a), to_float(b))
            ok = _close(got, want)
            tag = 'PASS' if ok else 'FAIL'
            if not ok:
                fails += 1
            print(f'[{tag}] {x!r:>15} {op_sym[op]} {y!r:<15}'
                  f'  ->  {got!r:>24}   (native {want!r:>22})   [{format_words(r)}]')
        total = len(cases)
        print(f'\n{total - fails}/{total} pass, {fails} fail')
        sys.exit(1 if fails else 0)
