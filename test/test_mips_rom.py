#!/usr/bin/env python3

import cocotb
from cocotb.triggers import Timer


def bits_to_int(bitstr: str) -> int:
    return int(bitstr.replace("_", ""), 2)


@cocotb.test()
async def test_mips_rom(dut):
    expected = {
        0:  "00000001001011100100100000100000",  # add  $t1, $t1, $t6
        1:  "00000001010010010111000000100010",  # sub  $t6, $t2, $t1
        63: "00010001000010111111111111111010",   # beq  $t0, $t3, 0xFFFA
        1023: "00001000000000000000000000000000", # j 0x0
    }

    # Verifica toda a ROM. Como addrWidth=10, são 1024 endereços.
    for addr in range(2 ** len(dut.addr)):
        dut.addr.value = addr
        await Timer(1, units="ns")

        got = int(dut.data.value)
        exp = bits_to_int(expected.get(addr, "0" * 32))

        assert got == exp, (
            f"addr={addr}: esperado 0x{exp:08X}, obtido 0x{got:08X}"
        )
