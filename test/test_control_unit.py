"""Teste da unidade de controle (decoder) usada no mips_word_toplevel."""
import cocotb
from cocotb.triggers import Timer

ADD, SUB, AND, OR, NOR, XOR = 0b010, 0b011, 0b100, 0b101, 0b110, 0b111

# (nome, opcode, funct) -> sinais esperados (None = nao importa)
CASOS = [
    ("add",   0x00, 0x20, dict(ula_op=ADD, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("addu",  0x00, 0x21, dict(ula_op=ADD, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("sub",   0x00, 0x22, dict(ula_op=SUB, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("subu",  0x00, 0x23, dict(ula_op=SUB, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("and",   0x00, 0x24, dict(ula_op=AND, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("or",    0x00, 0x25, dict(ula_op=OR,  write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("xor",   0x00, 0x26, dict(ula_op=XOR, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("nor",   0x00, 0x27, dict(ula_op=NOR, write_enable=1, rd_src=0, alu_src2=0, control_type=0)),
    ("jr",    0x00, 0x08, dict(write_enable=0, control_type=3, word_we=0)),
    ("addi",  0x08, 0x00, dict(ula_op=ADD, write_enable=1, rd_src=1, alu_src2=1, control_type=0)),
    ("addiu", 0x09, 0x00, dict(ula_op=ADD, write_enable=1, rd_src=1, alu_src2=1, control_type=0)),
    ("andi",  0x0C, 0x00, dict(ula_op=AND, write_enable=1, rd_src=1, alu_src2=2, control_type=0)),
    ("ori",   0x0D, 0x00, dict(ula_op=OR,  write_enable=1, rd_src=1, alu_src2=2, control_type=0)),
    ("xori",  0x0E, 0x00, dict(ula_op=XOR, write_enable=1, rd_src=1, alu_src2=2, control_type=0)),
    ("lw",    0x23, 0x00, dict(ula_op=ADD, write_enable=1, rd_src=1, alu_src2=1, mem_read=1, word_we=0)),
    ("sw",    0x2B, 0x00, dict(ula_op=ADD, write_enable=0, alu_src2=1, word_we=1, mem_read=0)),
    ("j",     0x02, 0x00, dict(write_enable=0, control_type=2, word_we=0)),
]


def val(sig):
    return int(str(sig.value), 2)


async def aplica(dut, opcode, funct, zero=0):
    dut.opcode.value = opcode
    dut.func.value = funct
    dut.zero.value = zero
    await Timer(1, "ns")


@cocotb.test()
async def test_instrucoes_suportadas(dut):
    for nome, op, fn, esp in CASOS:
        await aplica(dut, op, fn)
        assert val(getattr(dut, "except")) == 0, f"{nome}: except deveria ser 0"
        for sinal, v in esp.items():
            got = val(getattr(dut, sinal))
            assert got == v, f"{nome}: {sinal}={got}, esperado {v}"


@cocotb.test()
async def test_branches(dut):
    # beq: tomado quando zero = 1
    await aplica(dut, 0x04, 0, zero=1)
    assert val(dut.control_type) == 1 and val(dut.ula_op) == SUB and val(dut.write_enable) == 0
    await aplica(dut, 0x04, 0, zero=0)
    assert val(dut.control_type) == 0
    # bne: tomado quando zero = 0
    await aplica(dut, 0x05, 0, zero=0)
    assert val(dut.control_type) == 1 and val(dut.ula_op) == SUB and val(dut.write_enable) == 0
    await aplica(dut, 0x05, 0, zero=1)
    assert val(dut.control_type) == 0


@cocotb.test()
async def test_invalidas(dut):
    # slt, sll (nop), lui, slti, lb, sb, opcode inexistente
    for op, fn in [(0x00, 0x2A), (0x00, 0x00), (0x0F, 0), (0x0A, 0), (0x20, 0), (0x28, 0), (0x3F, 0)]:
        await aplica(dut, op, fn)
        assert val(getattr(dut, "except")) == 1, f"op={op:#x} fn={fn:#x}: except deveria ser 1"
        assert val(dut.write_enable) == 0 and val(dut.word_we) == 0, "instrucao invalida nao pode escrever"
