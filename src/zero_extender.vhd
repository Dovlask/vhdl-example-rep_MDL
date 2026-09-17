library ieee;
use ieee.std_logic_1164.all;

-- Extensor com zeros: imediato de 16 bits -> 32 bits
entity zero_extender is
  port(
    imm16        : in  std_logic_vector(15 downto 0);
    zero_ext_imm : out std_logic_vector(31 downto 0)
  );
end entity zero_extender;

architecture rtl of zero_extender is
begin
  zero_ext_imm <= x"0000" & imm16;
end architecture rtl;
