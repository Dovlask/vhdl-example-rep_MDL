library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

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
      tmp(0)    := "000000" & "01001" & "01110" & "01001" & "00000" & "100000";   --add $t1, $t1, $t6
      tmp(1)    := "000000" & "01010" & "01001" & "01110" & "00000" & "100010";   --sub $t6, $t2, $t1
      tmp(63)   := "000100" & "01000" & "01011" & "1111111111111010";             --beq, $t0, $t3, 0xFFFA
      tmp(1023) := "000010" & "00000000000000000000000000";                       --j 0x0;
      return tmp;
    end initMemory;

    signal memROM : blocoMemoria := initMemory;

begin
    data <= memROM (to_integer(unsigned(addr)));
end architecture;
