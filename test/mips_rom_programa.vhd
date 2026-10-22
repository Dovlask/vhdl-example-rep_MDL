library IEEE;
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
      tmp(0   ) := x"20080005";   -- 0x000: addi $t0, $zero, 5
      tmp(1   ) := x"20090007";   -- 0x004: addi $t1, $zero, 7
      tmp(2   ) := x"01095020";   -- 0x008: add  $t2, $t0, $t1
      tmp(3   ) := x"01095822";   -- 0x00C: sub  $t3, $t0, $t1
      tmp(4   ) := x"340C00F0";   -- 0x010: ori  $t4, $zero, 0x00F0
      tmp(5   ) := x"318D0030";   -- 0x014: andi $t5, $t4, 0x0030
      tmp(6   ) := x"398E00FF";   -- 0x018: xori $t6, $t4, 0x00FF
      tmp(7   ) := x"00007827";   -- 0x01C: nor  $t7, $zero, $zero
      tmp(8   ) := x"2017FFF8";   -- 0x020: addi $s7, $zero, -8
      tmp(9   ) := x"01EAB024";   -- 0x024: and  $s6, $t7, $t2
      tmp(10  ) := x"01AEA825";   -- 0x028: or   $s5, $t5, $t6
      tmp(11  ) := x"0149A026";   -- 0x02C: xor  $s4, $t2, $t1
      tmp(12  ) := x"AC0A0008";   -- 0x030: sw   $t2, 8($zero)
      tmp(13  ) := x"AD0B0020";   -- 0x034: sw   $t3, 0x20($t0)
      tmp(14  ) := x"8C100008";   -- 0x038: lw   $s0, 8($zero)
      tmp(15  ) := x"8C110024";   -- 0x03C: lw   $s1, 0x24($zero)
      tmp(16  ) := x"120A0001";   -- 0x040: beq  $s0, $t2, pula1
      tmp(17  ) := x"20120063";   -- 0x044: addi $s2, $zero, 99
      tmp(18  ) := x"15080001";   -- 0x048: bne  $t0, $t0, pula2
      tmp(19  ) := x"20120001";   -- 0x04C: addi $s2, $zero, 1
      tmp(20  ) := x"08000016";   -- 0x050: j    destino_j
      tmp(21  ) := x"2013004D";   -- 0x054: addi $s3, $zero, 77
      tmp(22  ) := x"20040064";   -- 0x058: addi $a0, $zero, 100
      tmp(23  ) := x"00800008";   -- 0x05C: jr   $a0
      tmp(24  ) := x"20130042";   -- 0x060: addi $s3, $zero, 66
      tmp(25  ) := x"2108FFFF";   -- 0x064: addi $t0, $t0, -1
      tmp(26  ) := x"00491020";   -- 0x068: add  $v0, $v0, $t1
      tmp(27  ) := x"1500FFFD";   -- 0x06C: bne  $t0, $zero, laco
      tmp(28  ) := x"AC020010";   -- 0x070: sw   $v0, 0x10($zero)
      tmp(29  ) := x"8C030010";   -- 0x074: lw   $v1, 0x10($zero)
      tmp(30  ) := x"0109602A";   -- 0x078: .word 0x0109602A
      tmp(31  ) := x"00712820";   -- 0x07C: add  $a1, $v1, $s1
      tmp(32  ) := x"020C3020";   -- 0x080: add  $a2, $s0, $t4
      tmp(33  ) := x"08000021";   -- 0x084: j    fim
      return tmp;
    end initMemory;

    signal memROM : blocoMemoria := initMemory;

begin
    data <= memROM (to_integer(unsigned(addr)));
end architecture;
