library ieee;
use ieee.std_logic_1164.all;

-- ULA de 32 bits (Pratica-3.2)
-- Modificacao para uso dentro da ULA: expoe o carry out dos bits 31 e 30
-- para o calculo da flag de overflow (ula_flags).
--   control = 010 -> A + B
--   control = 011 -> A - B
--   control = 100 -> A AND B
--   control = 101 -> A OR  B
--   control = 110 -> A NOR B
--   control = 111 -> A XOR B
entity ula_32bits is
  port(
    A, B    : in  std_logic_vector(31 downto 0);
    control : in  std_logic_vector(2 downto 0);
    result  : out std_logic_vector(31 downto 0);
    c_out31 : out std_logic;
    c_out30 : out std_logic
  );
end entity ula_32bits;

architecture rtl of ula_32bits is

  component ula_1bit is
    port(
      a, b, cin  : in  std_logic;
      control    : in  std_logic_vector(2 downto 0);
      outi, cout : out std_logic
    );
  end component;

  -- carry(i) = carry in do bit i ; carry(i+1) = carry out do bit i
  signal carry : std_logic_vector(32 downto 0);

begin

  carry(0) <= control(0);  -- +1 da subtracao

  gen_bits : for i in 0 to 31 generate
    bit_i : ula_1bit
      port map(
        a       => A(i),
        b       => B(i),
        cin     => carry(i),
        control => control,
        outi    => result(i),
        cout    => carry(i + 1)
      );
  end generate gen_bits;

  c_out31 <= carry(32);
  c_out30 <= carry(31);

end architecture rtl;
