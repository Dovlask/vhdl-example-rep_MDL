#!/usr/bin/env python3
"""Gera test/mips_rom_programa.vhd: mesma entidade da ROM (mips_rom), mas
pre-carregada com o programa de teste de mips_model.PROGRAMA.

Essa ROM e usada APENAS no teste do toplevel (src/mips_rom.vhd continua igual
ao template, que e o que o test_mips_rom.py verifica).

Uso:  python3 gen_rom_programa.py
"""
import os

from mips_model import programa_montado

here = os.path.dirname(os.path.abspath(__file__))
out_file = os.path.join(here, "mips_rom_programa.vhd")

linhas = []
for addr, word, txt in programa_montado():
    linhas.append(f'      tmp({addr >> 2:<4}) := x"{word:08X}";   -- 0x{addr:03X}: {txt}')

vhdl = f"""library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-- ROM SO PARA TESTE (gerada por test/gen_rom_programa.py -- nao editar a mao)
-- Mesma interface de src/mips_rom.vhd, com um programa que exercita o toplevel.
entity mips_rom is
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 10
   );
   port (
          addr : in  std_logic_vector (addrWidth-1 DOWNTO 0);
          data : out std_logic_vector (dataWidth-1 DOWNTO 0)
   );
end entity;

architecture bhv of mips_rom is

  type blocoMemoria is array(0 TO 2**addrWidth - 1) of std_logic_vector(dataWidth-1 DOWNTO 0);

  function initMemory
        return blocoMemoria is variable tmp : blocoMemoria := (others => (others => '0'));
  begin
{chr(10).join(linhas)}
      return tmp;
    end initMemory;

    signal memROM : blocoMemoria := initMemory;

begin
    data <= memROM (to_integer(unsigned(addr)));
end architecture;
"""

with open(out_file, "w") as f:
    f.write(vhdl)
print(f"gerado {out_file} ({len(linhas)} instrucoes)")
