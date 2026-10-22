#!/usr/bin/env python3

#!/usr/bin/env python3

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


def word_addr(byte_addr: int) -> int:
    return byte_addr >> 2


@cocotb.test()
async def test_mips_ram(dut):
    # Clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Estado inicial
    dut.reset.value = 0
    dut.word_we.value = 0
    dut.addr.value = 0
    dut.data_in.value = 0

    # Aplica reset assíncrono
    dut.reset.value = 1
    await Timer(1, units="ns")
    assert int(dut.data_out.value) == 0, "data_out deveria ser 0 durante reset"

    # Remove reset
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    # Verifica que a RAM começa zerada em alguns endereços
    for a in [0, 4, 16, 252, 1020, 4092]:
        dut.addr.value = a
        await Timer(1, units="ns")
        got = int(dut.data_out.value)
        assert got == 0, f"addr=0x{a:08X}: esperado 0, obtido 0x{got:08X}"

    # Escreve alguns valores em endereços diferentes
    tests = [
        (0x00000000, 0x12345678),
        (0x00000004, 0xDEADBEEF),
        (0x000000FC, 0xA5A5A5A5),
        (0x00000FFC, 0x0BADF00D),  # último endereço da RAM (word-address 1023)
    ]

    for addr, data in tests:
        dut.addr.value = addr
        dut.data_in.value = data
        dut.word_we.value = 1
        await RisingEdge(dut.clk)
        dut.word_we.value = 0

        # Leitura assíncrona logo após a escrita
        await Timer(1, units="ns")
        got = int(dut.data_out.value)
        assert got == data, (
            f"write/read addr=0x{addr:08X}: esperado 0x{data:08X}, obtido 0x{got:08X}"
        )

    # Confere que o endereçamento ignora os 2 bits menos significativos
    # addr 0x00000000 e 0x00000003 mapeiam para a mesma palavra
    dut.addr.value = 0x00000003
    await Timer(1, units="ns")
    got = int(dut.data_out.value)
    assert got == 0x12345678, (
        f"endereçamento desalinhado: esperado 0x12345678, obtido 0x{got:08X}"
    )

    # Confere que escrita não ocorre com word_we = 0
    dut.addr.value = 0x00000004
    dut.data_in.value = 0xCAFEBABE
    dut.word_we.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    got = int(dut.data_out.value)
    assert got == 0xDEADBEEF, (
        f"write enable desligado: esperado 0xDEADBEEF, obtido 0x{got:08X}"
    )

    # Reset final limpa tudo
    dut.reset.value = 1
    await Timer(1, units="ns")
    for a in [0, 4, 16, 252, 1020, 4092]:
        dut.addr.value = a
        await Timer(1, units="ns")
        got = int(dut.data_out.value)
        assert got == 0, f"após reset addr=0x{a:08X}: esperado 0, obtido 0x{got:08X}"
