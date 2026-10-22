"""Teste do MIPS completo (mips_word_toplevel) com a ROM de teste (test/mips_rom_programa.vhd).

A cada ciclo compara PC, instrucao, saida da ULA e except com o modelo em
mips_model.py (que executa o mesmo programa instrucao por instrucao).
"""
import cocotb
from cocotb.triggers import Timer

from mips_model import MipsModel, programa_montado


def u(sig):
    v = sig.value
    if hasattr(v, "to_unsigned"):
        return v.to_unsigned()
    return v.integer


async def tick(dut):
    dut.clk.value = 0
    await Timer(5, "ns")
    dut.clk.value = 1
    await Timer(5, "ns")


@cocotb.test()
async def test_programa_completo(dut):
    prog = programa_montado()
    model = MipsModel({addr >> 2: word for addr, word, _ in prog})
    texto = {addr: txt for addr, _, txt in prog}

    dut.clk.value = 0
    dut.reset.value = 1
    await Timer(5, "ns")
    await tick(dut)
    dut.reset.value = 0
    await Timer(1, "ns")

    fim = prog[-1][0]
    visitados = set()
    for ciclo in range(120):
        await Timer(1, "ns")
        esperado = model.step()
        pc, inst = u(dut.pc_out), u(dut.inst_out)
        onde = f"ciclo {ciclo}, PC=0x{esperado['pc']:03X} ({texto.get(esperado['pc'], '?')})"
        assert pc == esperado["pc"], f"{onde}: PC=0x{pc:08X}"
        assert inst == esperado["inst"], f"{onde}: inst=0x{inst:08X}"
        if esperado["alu"] is not None:
            alu = u(dut.alu_out)
            assert alu == esperado["alu"], f"{onde}: alu_out=0x{alu:08X}, esperado 0x{esperado['alu']:08X}"
        exc = int(str(getattr(dut, "except").value))   # "except" e palavra reservada do Python
        assert exc == esperado["except"], f"{onde}: except={exc}"
        visitados.add(pc)
        await tick(dut)
        if pc == fim and ciclo > 5:
            break

    # garante que o programa chegou ao fim e que as instrucoes "puladas" nao rodaram
    assert fim in visitados, "o programa nao chegou ao 'j fim'"
    for addr, _, txt in prog:
        if "NAO executa" in txt:
            assert addr not in visitados, f"executou instrucao que deveria ser pulada: {txt}"

    # estado final dos registradores (pelo modelo, que foi conferido ciclo a ciclo)
    R = model.R
    assert R[2] == 35 and R[3] == 35          # v0, v1 (laco + sw/lw)
    assert R[5] == 33 and R[6] == 252         # a1, a2
    assert R[18] == 1 and R[19] == 0          # s2 = 1 (bne nao tomado), s3 nunca escrito
    assert R[17] == 0xFFFFFFFE                # s1 = -2 lido da RAM


@cocotb.test()
async def test_except_instrucao_invalida(dut):
    """O slt (nao suportado nesta versao) deve levantar except e nao escrever nada."""
    prog = programa_montado()
    addr_slt = next(a for a, _, t in prog if t.startswith(".word"))

    dut.clk.value = 0
    dut.reset.value = 1
    await Timer(5, "ns")
    await tick(dut)
    dut.reset.value = 0

    for _ in range(120):
        await Timer(1, "ns")
        if u(dut.pc_out) == addr_slt:
            break
        await tick(dut)
    assert u(dut.pc_out) == addr_slt
    assert int(str(getattr(dut, "except").value)) == 1
    await tick(dut)
    await Timer(1, "ns")
    assert int(str(getattr(dut, "except").value)) == 0
