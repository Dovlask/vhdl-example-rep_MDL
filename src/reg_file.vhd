library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Banco de registradores do MIPS: 32 registradores x 32 bits
--   2 portas de leitura (combinacionais) e 1 porta de escrita (sincrona)
--   $0 e sempre zero (escritas em $0 sao ignoradas)
entity reg_file is
  port(
    clk    : in  std_logic;
    rst    : in  std_logic;
    A_addr : in  std_logic_vector(4 downto 0);
    B_addr : in  std_logic_vector(4 downto 0);
    W_addr : in  std_logic_vector(4 downto 0);
    W_data : in  std_logic_vector(31 downto 0);
    W_en   : in  std_logic;
    A_data : out std_logic_vector(31 downto 0);
    B_data : out std_logic_vector(31 downto 0)
  );
end entity reg_file;

architecture rtl of reg_file is

  type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
  signal R : reg_array := (others => (others => '0'));

begin

  process(clk, rst)
  begin
    if rst = '1' then
      R <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if W_en = '1' and W_addr /= "00000" then
        R(to_integer(unsigned(W_addr))) <= W_data;
      end if;
      R(0) <= (others => '0');
    end if;
  end process;

  A_data <= (others => '0') when A_addr = "00000" else R(to_integer(unsigned(A_addr)));
  B_data <= (others => '0') when B_addr = "00000" else R(to_integer(unsigned(B_addr)));

end architecture rtl;
