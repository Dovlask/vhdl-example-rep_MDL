"""Mini montador + simulador (ISS) do MIPS "word" da APS-1-4.

Usado por:
  - gen_rom_programa.py  -> gera test/mips_rom_programa.vhd (ROM so para teste)
  - test_mips_word_toplevel.py -> compara o hardware com o modelo, ciclo a ciclo
"""

MASK = 0xFFFFFFFF

REGS = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3, "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11, "t4": 12, "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25, "k0": 26, "k1": 27, "gp": 28, "sp": 29, "fp": 30, "ra": 31,
}

R_FUNCT = {"add": 0x20, "addu": 0x21, "sub": 0x22, "subu": 0x23,
           "and": 0x24, "or": 0x25, "xor": 0x26, "nor": 0x27, "jr": 0x08}
I_OP = {"addi": 0x08, "addiu": 0x09, "andi": 0x0C, "ori": 0x0D, "xori": 0x0E,
        "lw": 0x23, "sw": 0x2B, "beq": 0x04, "bne": 0x05}
J_OP = {"j": 0x02}


def reg(tok):
    tok = tok.strip().lstrip("$")
    return int(tok) if tok.isdigit() else REGS[tok]


def imm(tok):
    return int(tok.strip(), 0)


def assemble(program):
    """program: lista de strings (pode ter 'label:' e comentarios com #).
    Retorna lista de (endereco, palavra, texto)."""
    lines, labels, addr = [], {}, 0
    for raw in program:
        txt = raw.split("#")[0].strip()
        if not txt:
            continue
        if txt.endswith(":"):
            labels[txt[:-1]] = addr
            continue
        lines.append((addr, txt))
        addr += 4

    out = []
    for addr, txt in lines:
        mn, _, rest = txt.partition(" ")
        args = [a.strip() for a in rest.split(",")] if rest else []
        if mn == ".word":                       # palavra crua (ex.: instrucao nao suportada)
            word = imm(args[0]) & MASK
        elif mn in R_FUNCT:
            if mn == "jr":
                rs, rt, rd = reg(args[0]), 0, 0
            else:
                rd, rs, rt = reg(args[0]), reg(args[1]), reg(args[2])
            word = (rs << 21) | (rt << 16) | (rd << 11) | R_FUNCT[mn]
        elif mn in ("lw", "sw"):
            rt = reg(args[0])
            off, base = args[1].split("(")
            word = (I_OP[mn] << 26) | (reg(base.rstrip(")")) << 21) | (rt << 16) | (imm(off) & 0xFFFF)
        elif mn in ("beq", "bne"):
            rs, rt = reg(args[0]), reg(args[1])
            target = labels[args[2]] if args[2] in labels else None
            off = ((target - (addr + 4)) >> 2) if target is not None else imm(args[2])
            word = (I_OP[mn] << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)
        elif mn in I_OP:
            rt, rs = reg(args[0]), reg(args[1])
            word = (I_OP[mn] << 26) | (rs << 21) | (rt << 16) | (imm(args[2]) & 0xFFFF)
        elif mn in J_OP:
            target = labels[args[0]] if args[0] in labels else imm(args[0])
            word = (J_OP[mn] << 26) | ((target >> 2) & 0x3FFFFFF)
        else:
            raise ValueError(f"instrucao nao suportada: {txt}")
        out.append((addr, word, txt))
    return out


def sext16(x):
    x &= 0xFFFF
    return x - 0x10000 if x & 0x8000 else x


class MipsModel:
    """Executa uma instrucao por step(), como o processador monociclo."""

    def __init__(self, rom_words):
        self.rom = rom_words          # dict: indice da palavra -> instrucao
        self.R = [0] * 32
        self.M = {}                   # indice da palavra -> valor
        self.pc = 0

    def step(self):
        inst = self.rom.get((self.pc >> 2) & 0x3FF, 0)
        op, rs, rt, rd = inst >> 26, (inst >> 21) & 31, (inst >> 16) & 31, (inst >> 11) & 31
        funct, i16 = inst & 0x3F, inst & 0xFFFF
        A, B = self.R[rs], self.R[rt]
        pc4 = (self.pc + 4) & MASK
        nxt, alu, wreg, wval, exc = pc4, None, None, None, 0
        if op == 0:
            if funct in (0x20, 0x21):
                alu = (A + B) & MASK
            elif funct in (0x22, 0x23):
                alu = (A - B) & MASK
            elif funct == 0x24:
                alu = A & B
            elif funct == 0x25:
                alu = A | B
            elif funct == 0x26:
                alu = A ^ B
            elif funct == 0x27:
                alu = (~(A | B)) & MASK
            elif funct == 0x08:
                nxt = A
            else:
                exc = 1
            if alu is not None:
                wreg, wval = rd, alu
        elif op in (0x08, 0x09):
            alu = (A + sext16(i16)) & MASK
            wreg, wval = rt, alu
        elif op == 0x0C:
            alu = A & i16; wreg, wval = rt, alu
        elif op == 0x0D:
            alu = A | i16; wreg, wval = rt, alu
        elif op == 0x0E:
            alu = A ^ i16; wreg, wval = rt, alu
        elif op == 0x23:
            alu = (A + sext16(i16)) & MASK
            wreg, wval = rt, self.M.get((alu >> 2) & 0x3FF, 0)
        elif op == 0x2B:
            alu = (A + sext16(i16)) & MASK
            self.M[(alu >> 2) & 0x3FF] = B
        elif op in (0x04, 0x05):
            alu = (A - B) & MASK
            taken = (alu == 0) if op == 0x04 else (alu != 0)
            if taken:
                nxt = (pc4 + (sext16(i16) << 2)) & MASK
        elif op == 0x02:
            nxt = (pc4 & 0xF0000000) | ((inst & 0x3FFFFFF) << 2)
        else:
            exc = 1
        if wreg:                       # $0 nunca e escrito
            self.R[wreg] = wval
        info = {"pc": self.pc, "inst": inst, "alu": alu, "except": exc}
        self.pc = nxt
        return info


# Programa de teste: exercita R, I, lw/sw, beq/bne (tomado e nao tomado), j, jr e um laco.
PROGRAMA = [
    "inicio:",
    "addi $t0, $zero, 5        # t0 = 5",
    "addi $t1, $zero, 7        # t1 = 7",
    "add  $t2, $t0, $t1        # t2 = 12",
    "sub  $t3, $t0, $t1        # t3 = -2",
    "ori  $t4, $zero, 0x00F0   # t4 = 0xF0 (zero ext)",
    "andi $t5, $t4, 0x0030     # t5 = 0x30",
    "xori $t6, $t4, 0x00FF     # t6 = 0x0F",
    "nor  $t7, $zero, $zero    # t7 = 0xFFFFFFFF",
    "addi $s7, $zero, -8       # s7 = -8 (sign ext)",
    "and  $s6, $t7, $t2        # s6 = 12",
    "or   $s5, $t5, $t6        # s5 = 0x3F",
    "xor  $s4, $t2, $t1        # s4 = 12 ^ 7 = 11",
    "sw   $t2, 8($zero)        # M[8] = 12",
    "sw   $t3, 0x20($t0)       # M[0x25 -> palavra 9] = -2 (2 LSBs ignorados)",
    "lw   $s0, 8($zero)        # s0 = 12",
    "lw   $s1, 0x24($zero)     # s1 = -2",
    "beq  $s0, $t2, pula1      # tomado",
    "addi $s2, $zero, 99       # NAO executa",
    "pula1:",
    "bne  $t0, $t0, pula2      # nao tomado",
    "addi $s2, $zero, 1        # executa: s2 = 1",
    "pula2:",
    "j    destino_j",
    "addi $s3, $zero, 77       # NAO executa",
    "destino_j:",
    "addi $a0, $zero, laco_addr",
    "jr   $a0                  # vai para 'laco'",
    "addi $s3, $zero, 66       # NAO executa",
    "laco:",
    "addi $t0, $t0, -1         # t0--",
    "add  $v0, $v0, $t1        # v0 += 7",
    "bne  $t0, $zero, laco     # repete 5 vezes",
    "sw   $v0, 0x10($zero)     # M[0x10] = 35",
    "lw   $v1, 0x10($zero)     # v1 = 35",
    ".word 0x0109602A          # slt $t4,$t0,$t1 -> nao suportada: except=1, nao escreve",
    "add  $a1, $v1, $s1        # a1 = 35 + (-2) = 33 (confere valores lidos com lw)",
    "add  $a2, $s0, $t4        # a2 = 12 + 0xF0 = 252 (t4 nao foi alterado pelo slt)",
    "fim:",
    "j    fim                  # para aqui",
]


def programa_montado():
    # resolve o endereco de 'laco' para usar como imediato do addi
    labels, addr = {}, 0
    for raw in PROGRAMA:
        t = raw.split("#")[0].strip()
        if not t:
            continue
        if t.endswith(":"):
            labels[t[:-1]] = addr
        else:
            addr += 4
    prog = [l.replace("laco_addr", str(labels["laco"])) for l in PROGRAMA]
    return assemble(prog)
