library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Toplevel para validar a ULA na placa (APS-1-1.4)
--
--   SW(3 downto 0) : A (4 bits com extensao de sinal)
--   SW(6 downto 4) : B (3 bits com extensao de sinal)
--   SW(9 downto 7) : control (010 add, 011 sub, 100 and, 101 or, 110 nor, 111 xor)
--   KEY(0)         : segurado -> A = 0x7FFFFFFF (para testar overflow)
--   LEDR(6 downto 0) : result(6 downto 0)
--   LEDR(7) : flag_zero   LEDR(8) : flag_neg   LEDR(9) : flag_overflow
--   HEX5..HEX0 : result(23 downto 0) em hexadecimal
entity toplevel_ula is
  port(
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    SW       : in  std_logic_vector(9 downto 0);
    LEDR     : out std_logic_vector(9 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0)
  );
end entity toplevel_ula;

architecture rtl of toplevel_ula is

  component ULA is
    port (
      A             : in  std_logic_vector(31 downto 0);
      B             : in  std_logic_vector(31 downto 0);
      control       : in  std_logic_vector(2 downto 0);
      result        : out std_logic_vector(31 downto 0);
      flag_neg      : out std_logic;
      flag_zero     : out std_logic;
      flag_overflow : out std_logic
    );
  end component;

  component hex7seg is
    port(
      hex : in  std_logic_vector(3 downto 0);
      seg : out std_logic_vector(6 downto 0)
    );
  end component;

  signal A, B          : std_logic_vector(31 downto 0);
  signal result        : std_logic_vector(31 downto 0);
  signal flag_neg      : std_logic;
  signal flag_zero     : std_logic;
  signal flag_overflow : std_logic;

begin

  A <= x"7FFFFFFF" when KEY(0) = '0'
       else std_logic_vector(resize(signed(SW(3 downto 0)), 32));
  B <= std_logic_vector(resize(signed(SW(6 downto 4)), 32));

  u_ula : ULA
    port map(
      A             => A,
      B             => B,
      control       => SW(9 downto 7),
      result        => result,
      flag_neg      => flag_neg,
      flag_zero     => flag_zero,
      flag_overflow => flag_overflow
    );

  LEDR(6 downto 0) <= result(6 downto 0);
  LEDR(7)          <= flag_zero;
  LEDR(8)          <= flag_neg;
  LEDR(9)          <= flag_overflow;

  u_hex0 : hex7seg port map(hex => result(3 downto 0),   seg => HEX0);
  u_hex1 : hex7seg port map(hex => result(7 downto 4),   seg => HEX1);
  u_hex2 : hex7seg port map(hex => result(11 downto 8),  seg => HEX2);
  u_hex3 : hex7seg port map(hex => result(15 downto 12), seg => HEX3);
  u_hex4 : hex7seg port map(hex => result(19 downto 16), seg => HEX4);
  u_hex5 : hex7seg port map(hex => result(23 downto 20), seg => HEX5);

end architecture rtl;
