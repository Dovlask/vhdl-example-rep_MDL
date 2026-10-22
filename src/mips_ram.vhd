library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_ram IS
   generic (
          dataWidth: natural := 32;
          addrWidth: natural := 32;
          memoryAddrWidth:  natural := 10
   );
   port ( clk      : in  std_logic;
          addr     : in  std_logic_vector(addrWidth-1 downto 0);
          data_in  : in  std_logic_vector(dataWidth-1 downto 0);
          data_out : out std_logic_vector(dataWidth-1 downto 0);
          word_we  : in  std_logic;
          reset    : in  std_logic
        );
end entity;

architecture bhv OF mips_ram IS
  type blocoMemoria IS ARRAY(0 TO 2**memoryAddrWidth - 1) OF std_logic_vector(dataWidth-1 DOWNTO 0);

  signal memRAM: blocoMemoria := (others => (others => '0'));

   signal addr_local : std_logic_vector(memoryAddrWidth-1 downto 0);

begin

  -- Ajusta o enderecamento para o acesso de 32 bits.
  addr_local <= addr(memoryAddrWidth+1 downto 2);

  process(clk, reset)
  begin
      if(reset = '1') then
          memRAM <= (others => (others => '0'));

      elsif(rising_edge(clk)) then
          if(word_we = '1') then
              memRAM(to_integer(unsigned(addr_local))) <= data_in;
          end if;
      end if;
  end process;

  -- A leitura deve ser sempre assincrona:
  data_out <= memRAM(to_integer(unsigned(addr_local)));

end architecture;
