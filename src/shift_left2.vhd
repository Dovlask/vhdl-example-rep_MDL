library ieee;
use ieee.std_logic_1164.all;

-- Deslocamento de 2 bits para a esquerda (<<2): BranchAddr = SignExtImm << 2
--   out = in(29 downto 0) & "00"
entity shift_left2 is
  port(
    din  : in  std_logic_vector(31 downto 0);
    dout : out std_logic_vector(31 downto 0)
  );
end entity shift_left2;

architecture rtl of shift_left2 is
begin
  dout <= din(29 downto 0) & "00";
end architecture rtl;
