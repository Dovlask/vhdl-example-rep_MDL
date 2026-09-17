library ieee;
use ieee.std_logic_1164.all;

-- Flags da ULA (Pratica-3.5)
entity ula_flags is
  port(
    -- dados da saida da ULA
    c_out31       : in  std_logic;
    c_out30       : in  std_logic;
    ula_out       : in  std_logic_vector(31 downto 0);

    flag_neg      : out std_logic;
    flag_zero     : out std_logic;
    flag_overflow : out std_logic
  );
end entity ula_flags;

architecture rtl of ula_flags is
begin
  flag_neg      <= ula_out(31);
  flag_zero     <= '1' when ula_out = x"00000000" else '0';
  flag_overflow <= c_out31 xor c_out30;
end architecture rtl;
