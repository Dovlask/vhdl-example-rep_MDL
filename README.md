# DESCOMP – Projeto MIPS (grupo MDL)

Projeto Quartus (DE0-CV, Cyclone V `5CEBA4F23C7`) + testes cocotb/GHDL.

## Estrutura

| Arquivo | Descrição |
|---|---|
| `src/ula_fullAdder.vhd` | somador completo de 1 bit |
| `src/ula_logicUnit.vhd` | unidade lógica (AND / OR / NOR / XOR) |
| `src/ula_1bit.vhd` | ULA de 1 bit (fullAdder + logicUnit + mux) |
| `src/ula_32bits.vhd` | ULA de 32 bits (expõe `c_out31` / `c_out30` para as flags) |
| `src/ula_flags.vhd` | flags `neg`, `zero`, `overflow` |
| `src/ula.vhd` | **ULA** (`ula_32bits` + `ula_flags`) |
| `src/reg_file.vhd` | banco de registradores 32x32 (`$0` sempre 0) |
| `src/sign_extender.vhd` / `src/zero_extender.vhd` | extensores do imediato de 16 bits |
| `src/arith_machine.vhd` | **máquina aritmética** (reg_file + ULA + extensores + muxes) |
| `src/toplevel_ula.vhd` | toplevel para validar a ULA na placa (APS-1-1) |
| `src/toplevel_mips.vhd` | toplevel para validar a máquina aritmética na placa (APS-1-3) |
| `src/hex7seg.vhd` | decodificador hex → 7 segmentos |
| `test/` | testes cocotb (`test_ula.py`, `test_reg_file.py`, `test_arith_machine.py`) |

Controle da ULA: `010` soma, `011` subtração, `100` AND, `101` OR, `110` NOR, `111` XOR.

## Testes (cocotb)

```bash
docker run -it --rm -v $(pwd):/job rafaelcorsi/pl-descomp-cocotb:latest
make -C test/                  # todos os testes
make -C test/ DUT=ula          # só a ULA
make -C test/ DUT=reg_file     # só o banco de registradores
```

O GitHub Actions roda os testes (`.github/workflows/cocotb.yml`) e a compilação do Quartus (`.github/workflows/quartus_tests.yml`) a cada push.

## Validação na placa

O projeto está com `toplevel_mips` como top-level. Para a ULA, no Quartus: botão direito em `toplevel_ula` → *Set as Top-Level Entity*.
Para gerar o RTL pedido nas entregas: *Set as Top-Level Entity* no componente (`ULA`, `reg_file` ou `arith_machine`) → *Analysis & Elaboration* → *Tools > Netlist Viewers > RTL Viewer*.

### `toplevel_mips` (máquina aritmética)

- `KEY0`: próxima instrução · `KEY1`: reset
- `HEX0`: número da instrução · `LEDR`: `ula_out(9:0)`
- `HEX1`: flags (bit2 = overflow, bit1 = negative, bit0 = zero) · `HEX5..HEX2`: `ula_out(15:0)` em hex

| HEX0 | Instrução | `ula_out` | LEDR (9..0) |
|---|---|---|---|
| 0 | `addi $1, $0, 10` | `0x0000000A` | `0000001010` |
| 1 | `addi $2, $0, 3` | `0x00000003` | `0000000011` |
| 2 | `add $3, $1, $2` | `0x0000000D` | `0000001101` |
| 3 | `sub $4, $1, $2` | `0x00000007` | `0000000111` |
| 4 | `and $5, $1, $2` | `0x00000002` | `0000000010` |
| 5 | `or $6, $1, $2` | `0x0000000B` | `0000001011` |
| 6 | `xor $7, $1, $2` | `0x00000009` | `0000001001` |
| 7 | `nor $8, $1, $2` | `0xFFFFFFF4` (neg) | `1111110100` |
| 8 | `sub $9, $2, $1` | `0xFFFFFFF9` (neg) | `1111111001` |
| 9 | `ori $10, $1, 0xF0` | `0x000000FA` | `0011111010` |
| A | `addi $11, $0, -1` | `0xFFFFFFFF` (neg) | `1111111111` |
| B | `sub $12, $1, $1` | `0x00000000` (zero) | `0000000000` |

As instruções 2–8 e B usam `$1` e `$2`: passe pelas instruções 0 e 1 antes (depois de um reset).

### `toplevel_ula` (ULA)

- `SW3..SW0`: A (4 bits com sinal) · `SW6..SW4`: B (3 bits com sinal) · `SW9..SW7`: controle
- `KEY0` pressionado: A = `0x7FFFFFFF` (teste de overflow)
- `LEDR6..LEDR0`: resultado · `LEDR7`: zero · `LEDR8`: negativo · `LEDR9`: overflow
- `HEX5..HEX0`: `result(23:0)` em hex
