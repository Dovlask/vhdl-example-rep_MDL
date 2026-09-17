library ieee;
use ieee.std_logic_1164.all;

-- ULA de 1 bit (Pratica-3.1)
--   control(0)  -> inverte b (subtracao)
--   control(1:0)-> operacao da unidade logica
--   control(2)  -> 0: saida aritmetica / 1: saida logica
entity ula_1bit is
  port(
    a, b, cin  : in  std_logic;
    control    : in  std_logic_vector(2 downto 0);
    outi, cout : out std_logic
  );
end entity ula_1bit;

architecture rtl of ula_1bit is

  component ula_fullAdder is
    port(
      a, b, cin : in  std_logic;
      s         : out std_logic;
      cout      : out std_logic
    );
  end component;

  component ula_logicUnit is
    port(
      a, b : in  std_logic;
      s    : in  std_logic_vector(1 downto 0);
      y    : out std_logic
    );
  end component;

  signal b_inv     : std_logic;
  signal sum_out   : std_logic;
  signal logic_out : std_logic;

begin

  b_inv <= b xor control(0);

  fa : ula_fullAdder
    port map(
      a    => a,
      b    => b_inv,
      cin  => cin,
      s    => sum_out,
      cout => cout
    );

  lu : ula_logicUnit
    port map(
      a => a,
      b => b,
      s => control(1 downto 0),
      y => logic_out
    );

  outi <= logic_out when control(2) = '1' else sum_out;

end architecture rtl;
