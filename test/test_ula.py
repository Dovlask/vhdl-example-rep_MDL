import random

import cocotb
from cocotb.triggers import Timer

MASK = 0xFFFFFFFF

ADD = 0b010
SUB = 0b011
AND = 0b100
OR = 0b101
NOR = 0b110
XOR = 0b111


def to_uint(sig):
    v = sig.value
    if hasattr(v, "to_unsigned"):
        return v.to_unsigned()
    return v.integer


def to_bit(sig):
    return int(str(sig.value)[-1])


async def apply(dut, a, b, control):
    dut.A.value = a & MASK
    dut.B.value = b & MASK
    dut.control.value = control
    await Timer(1, "ns")
    return to_uint(dut.result)


def vectors(n=20):
    fixed = [(0, 0), (1, 1), (5, 3), (3, 5), (MASK, 1), (0x7FFFFFFF, 1),
             (0x80000000, 1), (0x80000000, 0x80000000), (0x12345678, 0x0F0F0F0F)]
    rnd = [(random.getrandbits(32), random.getrandbits(32)) for _ in range(n)]
    return fixed + rnd


@cocotb.test()
async def test_ula_add(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, ADD)
        assert got == (a + b) & MASK, f"ADD {a:#x} + {b:#x}: esperado {(a + b) & MASK:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_sub(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, SUB)
        assert got == (a - b) & MASK, f"SUB {a:#x} - {b:#x}: esperado {(a - b) & MASK:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_and(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, AND)
        assert got == (a & b), f"AND {a:#x} & {b:#x}: esperado {a & b:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_or(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, OR)
        assert got == (a | b), f"OR {a:#x} | {b:#x}: esperado {a | b:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_nor(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, NOR)
        exp = ~(a | b) & MASK
        assert got == exp, f"NOR {a:#x}, {b:#x}: esperado {exp:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_xor(dut):
    for a, b in vectors():
        got = await apply(dut, a, b, XOR)
        assert got == (a ^ b), f"XOR {a:#x} ^ {b:#x}: esperado {a ^ b:#x}, obtido {got:#x}"


@cocotb.test()
async def test_ula_flag_neg(dut):
    await apply(dut, 1, 2, SUB)          # 1 - 2 = -1
    assert to_bit(dut.flag_neg) == 1
    await apply(dut, 2, 1, SUB)          # 2 - 1 = 1
    assert to_bit(dut.flag_neg) == 0
    await apply(dut, 0x80000000, 0, OR)  # bit 31 em 1
    assert to_bit(dut.flag_neg) == 1


@cocotb.test()
async def test_ula_flag_zero(dut):
    await apply(dut, 7, 7, SUB)          # 7 - 7 = 0
    assert to_bit(dut.flag_zero) == 1
    await apply(dut, 0xF0, 0x0F, AND)    # 0xF0 & 0x0F = 0
    assert to_bit(dut.flag_zero) == 1
    await apply(dut, 7, 6, SUB)          # 7 - 6 = 1
    assert to_bit(dut.flag_zero) == 0


@cocotb.test()
async def test_ula_flag_overflow(dut):
    await apply(dut, 0x7FFFFFFF, 1, ADD)           # max positivo + 1
    assert to_bit(dut.flag_overflow) == 1
    await apply(dut, 0x80000000, MASK, ADD)        # min negativo + (-1)
    assert to_bit(dut.flag_overflow) == 1
    await apply(dut, 0x80000000, 1, SUB)           # min negativo - 1
    assert to_bit(dut.flag_overflow) == 1
    await apply(dut, 0x7FFFFFFF, MASK, SUB)        # max positivo - (-1)
    assert to_bit(dut.flag_overflow) == 1
    await apply(dut, 5, 3, ADD)
    assert to_bit(dut.flag_overflow) == 0
    await apply(dut, 5, 3, SUB)
    assert to_bit(dut.flag_overflow) == 0
    await apply(dut, MASK, 1, ADD)                 # -1 + 1 = 0 (carry, sem overflow)
    assert to_bit(dut.flag_overflow) == 0
