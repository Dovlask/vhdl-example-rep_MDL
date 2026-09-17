import random

import cocotb
from cocotb.triggers import Timer

MASK = 0xFFFFFFFF


def to_uint(sig):
    v = sig.value
    if hasattr(v, "to_unsigned"):
        return v.to_unsigned()
    return v.integer


async def tick(dut):
    """Um ciclo de clock (borda de subida no meio)."""
    dut.clk.value = 0
    await Timer(5, "ns")
    dut.clk.value = 1
    await Timer(5, "ns")


async def reset(dut):
    dut.clk.value = 0
    dut.W_en.value = 0
    dut.W_addr.value = 0
    dut.W_data.value = 0
    dut.A_addr.value = 0
    dut.B_addr.value = 0
    dut.rst.value = 1
    await tick(dut)
    dut.rst.value = 0
    await tick(dut)


async def write(dut, addr, data):
    dut.W_addr.value = addr
    dut.W_data.value = data & MASK
    dut.W_en.value = 1
    await tick(dut)
    dut.W_en.value = 0


async def read(dut, a_addr, b_addr):
    dut.A_addr.value = a_addr
    dut.B_addr.value = b_addr
    await Timer(1, "ns")
    return to_uint(dut.A_data), to_uint(dut.B_data)


@cocotb.test()
async def test_reg_file_reset(dut):
    await reset(dut)
    for addr in range(32):
        a, b = await read(dut, addr, 31 - addr)
        assert a == 0 and b == 0, f"apos reset R[{addr}]={a:#x}, R[{31 - addr}]={b:#x}"


@cocotb.test()
async def test_reg_file_write_read_all(dut):
    await reset(dut)
    values = {addr: random.getrandbits(32) for addr in range(1, 32)}
    for addr, val in values.items():
        await write(dut, addr, val)
    for addr, val in values.items():
        a, b = await read(dut, addr, addr)
        assert a == val, f"A_data: R[{addr}] esperado {val:#x}, obtido {a:#x}"
        assert b == val, f"B_data: R[{addr}] esperado {val:#x}, obtido {b:#x}"


@cocotb.test()
async def test_reg_file_two_read_ports(dut):
    await reset(dut)
    await write(dut, 4, 0xDEADBEEF)
    await write(dut, 9, 0x12345678)
    a, b = await read(dut, 4, 9)
    assert (a, b) == (0xDEADBEEF, 0x12345678), f"obtido A={a:#x} B={b:#x}"
    a, b = await read(dut, 9, 4)
    assert (a, b) == (0x12345678, 0xDEADBEEF), f"obtido A={a:#x} B={b:#x}"


@cocotb.test()
async def test_reg_file_r0_always_zero(dut):
    await reset(dut)
    await write(dut, 0, 0xFFFFFFFF)
    a, b = await read(dut, 0, 0)
    assert a == 0 and b == 0, f"R[0] deveria ser 0, obtido A={a:#x} B={b:#x}"


@cocotb.test()
async def test_reg_file_write_enable(dut):
    await reset(dut)
    await write(dut, 5, 0xCAFE)
    # W_en = 0: nao pode escrever
    dut.W_addr.value = 5
    dut.W_data.value = 0xBAD
    dut.W_en.value = 0
    await tick(dut)
    a, _ = await read(dut, 5, 0)
    assert a == 0xCAFE, f"escreveu com W_en=0: R[5]={a:#x}"


@cocotb.test()
async def test_reg_file_sync_write(dut):
    await reset(dut)
    dut.A_addr.value = 7
    dut.W_addr.value = 7
    dut.W_data.value = 0xABCD
    dut.W_en.value = 1
    dut.clk.value = 0
    await Timer(5, "ns")
    a = to_uint(dut.A_data)
    assert a == 0, f"escrita antes da borda de clock: R[7]={a:#x}"
    dut.clk.value = 1
    await Timer(5, "ns")
    a = to_uint(dut.A_data)
    assert a == 0xABCD, f"escrita nao ocorreu na borda: R[7]={a:#x}"
    dut.W_en.value = 0


@cocotb.test()
async def test_reg_file_overwrite_and_reset(dut):
    await reset(dut)
    await write(dut, 31, 1)
    await write(dut, 31, 2)
    a, _ = await read(dut, 31, 0)
    assert a == 2, f"R[31] esperado 2, obtido {a}"
    dut.rst.value = 1
    await Timer(1, "ns")
    dut.rst.value = 0
    a, _ = await read(dut, 31, 0)
    assert a == 0, f"reset nao zerou R[31]: {a}"
