library ieee;
use ieee.std_logic_1164.all;

-- ULA do MIPS: integra ula_32bits + ula_flags
--   (ula_32bits -> ula_1bit -> ula_fullAdder / ula_logicUnit)
entity ULA is
  port (
    A             : in  std_logic_vector(31 downto 0);
    B             : in  std_logic_vector(31 downto 0);
    control       : in  std_logic_vector(2 downto 0);
    result        : out std_logic_vector(31 downto 0);
    flag_neg      : out std_logic;
    flag_zero     : out std_logic;
    flag_overflow : out std_logic
  );
end entity ULA;

architecture rtl of ULA is

  component ula_32bits is
    port(
      A, B    : in  std_logic_vector(31 downto 0);
      control : in  std_logic_vector(2 downto 0);
      result  : out std_logic_vector(31 downto 0);
      c_out31 : out std_logic;
      c_out30 : out std_logic
    );
  end component;

  component ula_flags is
    port(
      c_out31       : in  std_logic;
      c_out30       : in  std_logic;
      ula_out       : in  std_logic_vector(31 downto 0);
      flag_neg      : out std_logic;
      flag_zero     : out std_logic;
      flag_overflow : out std_logic
    );
  end component;

  signal result_s : std_logic_vector(31 downto 0);
  signal c31, c30 : std_logic;

begin

  u_ula32 : ula_32bits
    port map(
      A       => A,
      B       => B,
      control => control,
      result  => result_s,
      c_out31 => c31,
      c_out30 => c30
    );

  u_flags : ula_flags
    port map(
      c_out31       => c31,
      c_out30       => c30,
      ula_out       => result_s,
      flag_neg      => flag_neg,
      flag_zero     => flag_zero,
      flag_overflow => flag_overflow
    );

  result <= result_s;

end architecture rtl;
