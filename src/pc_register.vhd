library ieee;
use ieee.std_logic_1164.all;

-- Registrador do PC (32 bits): D -> Q na borda de subida quando enable = '1'.
-- reset assincrono leva o PC para 0x00000000 (inicio da ROM).
entity pc_register is
  port(
    clk    : in  std_logic;
    reset  : in  std_logic;
    enable : in  std_logic;
    D      : in  std_logic_vector(31 downto 0);
    Q      : out std_logic_vector(31 downto 0)
  );
end entity pc_register;

architecture rtl of pc_register is
begin
  process(clk, reset)
  begin
    if reset = '1' then
      Q <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' then
        Q <= D;
      end if;
    end if;
  end process;
end architecture rtl;
