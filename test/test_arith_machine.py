import cocotb
from cocotb.triggers import Timer

MASK = 0xFFFFFFFF

ADD, SUB, AND, OR, NOR, XOR = 0b010, 0b011, 0b100, 0b101, 0b110, 0b111
SRC_RT, SRC_SEXT, SRC_ZEXT = 0b00, 0b01, 0b10


def to_uint(sig):
    v = sig.value
    if hasattr(v, "to_unsigned"):
        return v.to_unsigned()
    return v.integer


def r_type(rs, rt, rd, funct):
    return (rs << 21) | (rt << 16) | (rd << 11) | funct


def i_type(op, rs, rt, imm):
    return (op << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)


async def tick(dut):
    dut.clk.value = 0
    await Timer(5, "ns")
    dut.clk.value = 1
    await Timer(5, "ns")


async def run(dut, instr, rd_src, ula_src2, ula_op, wr=1):
    """Aplica a instrucao, confere a saida combinacional e executa um ciclo."""
    dut.instr.value = instr
    dut.rd_src.value = rd_src
    dut.ula_src2.value = ula_src2
    dut.ula_op.value = ula_op
    dut.wr_enable.value = wr
    await Timer(1, "ns")
    out = to_uint(dut.ula_out)
    await tick(dut)
    return out


async def reset(dut):
    dut.reset.value = 1
    dut.wr_enable.value = 0
    dut.instr.value = 0
    dut.rd_src.value = 0
    dut.ula_src2.value = 0
    dut.ula_op.value = ADD
    await tick(dut)
    dut.reset.value = 0
    await tick(dut)


@cocotb.test()
async def test_arith_machine_program(dut):
    await reset(dut)
    assert await run(dut, i_type(0x08, 0, 1, 10), 1, SRC_SEXT, ADD) == 10          # addi $1,$0,10
    assert await run(dut, i_type(0x08, 0, 2, 3), 1, SRC_SEXT, ADD) == 3            # addi $2,$0,3
    assert await run(dut, r_type(1, 2, 3, 0x20), 0, SRC_RT, ADD) == 13             # add $3,$1,$2
    assert await run(dut, r_type(1, 2, 4, 0x22), 0, SRC_RT, SUB) == 7              # sub $4,$1,$2
    assert await run(dut, r_type(1, 2, 5, 0x24), 0, SRC_RT, AND) == 2              # and $5,$1,$2
    assert await run(dut, r_type(1, 2, 6, 0x25), 0, SRC_RT, OR) == 11              # or  $6,$1,$2
    assert await run(dut, r_type(1, 2, 7, 0x26), 0, SRC_RT, XOR) == 9              # xor $7,$1,$2
    assert await run(dut, r_type(1, 2, 8, 0x27), 0, SRC_RT, NOR) == (~11) & MASK   # nor $8,$1,$2
    assert await run(dut, r_type(2, 1, 9, 0x22), 0, SRC_RT, SUB) == (-7) & MASK    # sub $9,$2,$1
    assert int(str(dut.negative.value)) == 1
    assert await run(dut, i_type(0x0D, 1, 10, 0xF0), 1, SRC_ZEXT, OR) == 0xFA      # ori $10,$1,0xF0
    assert await run(dut, i_type(0x08, 0, 11, -1), 1, SRC_SEXT, ADD) == MASK       # addi $11,$0,-1
    assert await run(dut, i_type(0x0D, 0, 12, 0xFFFF), 1, SRC_ZEXT, OR) == 0xFFFF # ori $12,$0,0xFFFF
    assert await run(dut, r_type(1, 1, 13, 0x22), 0, SRC_RT, SUB) == 0             # sub $13,$1,$1
    assert int(str(dut.zero.value)) == 1
    # le de volta os registradores escritos (add $0 + $rt com escrita desabilitada)
    expected = {3: 13, 4: 7, 5: 2, 6: 11, 7: 9, 8: (~11) & MASK, 9: (-7) & MASK,
                10: 0xFA, 11: MASK, 12: 0xFFFF, 13: 0}
    for reg, val in expected.items():
        got = await run(dut, r_type(0, reg, 0, 0x20), 0, SRC_RT, ADD, wr=0)
        assert got == val, f"R[{reg}] esperado {val:#x}, obtido {got:#x}"


@cocotb.test()
async def test_arith_machine_r0_and_flags(dut):
    await reset(dut)
    await run(dut, i_type(0x08, 0, 0, 55), 1, SRC_SEXT, ADD)                       # addi $0,$0,55 (ignorado)
    assert await run(dut, r_type(0, 0, 0, 0x20), 0, SRC_RT, ADD, wr=0) == 0       # $0 continua 0
    await run(dut, i_type(0x08, 0, 4, -1), 1, SRC_SEXT, ADD)                       # $4 = -1
    out = await run(dut, r_type(4, 4, 5, 0x20), 0, SRC_RT, ADD)                    # $5 = -1 + -1 = -2
    assert out == (-2) & MASK
    assert int(str(dut.negative.value)) == 1
    assert int(str(dut.overflow.value)) == 0
    out = await run(dut, r_type(0, 4, 6, 0x27), 0, SRC_RT, NOR)                    # $6 = ~(0 | -1) = 0
    assert out == 0
    assert int(str(dut.zero.value)) == 1
    await run(dut, i_type(0x0D, 0, 7, 0x7FFF), 1, SRC_ZEXT, OR)                    # $7 = 0x7FFF
    out = await run(dut, i_type(0x08, 7, 8, 0x7FFF), 1, SRC_SEXT, ADD)             # $8 = 0x7FFF + 0x7FFF
    assert out == 0xFFFE
    assert int(str(dut.overflow.value)) == 0
