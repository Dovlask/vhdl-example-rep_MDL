"""Teste do calculo do proximo PC (nextPC)."""
import cocotb
from cocotb.triggers import Timer

MASK = 0xFFFFFFFF


def u(sig):
    v = sig.value
    if hasattr(v, "to_unsigned"):
        return v.to_unsigned()
    return v.integer


async def aplica(dut, ct, pc, inst26=0, branch=0, a=0):
    dut.control_type.value = ct
    dut.pc.value = pc
    dut.intruction.value = inst26
    dut.branch_addr.value = branch & MASK
    dut.a_data.value = a
    await Timer(1, "ns")
    return u(dut.nextPC)


@cocotb.test()
async def test_next_pc(dut):
    assert await aplica(dut, 0b00, 0x00000010) == 0x14                       # PC + 4
    assert await aplica(dut, 0b01, 0x00000040, branch=4) == 0x48             # branch para frente
    assert await aplica(dut, 0b01, 0x0000006C, branch=-12) == 0x64           # branch para tras
    assert await aplica(dut, 0b10, 0x00000050, inst26=0x16) == 0x58          # j
    assert await aplica(dut, 0b10, 0xF0000000, inst26=0x1) == 0xF0000004     # j usa PC+4[31:28]
    assert await aplica(dut, 0b11, 0x0000005C, a=0x64) == 0x64               # jr
