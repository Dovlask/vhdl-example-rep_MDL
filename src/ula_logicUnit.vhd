library ieee;
use ieee.std_logic_1164.all;

-- Unidade logica de 1 bit (Aula-5.3)
--   s = 00 -> a AND b
--   s = 01 -> a OR  b
--   s = 10 -> a NOR b
--   s = 11 -> a XOR b
entity ula_logicUnit is
  port(
    a, b : in  std_logic;
    s    : in  std_logic_vector(1 downto 0);
    y    : out std_logic
  );
end entity ula_logicUnit;

architecture rtl of ula_logicUnit is
begin
  with s select
    y <= (a and b) when "00",
         (a or b)  when "01",
         (a nor b) when "10",
         (a xor b) when others;
end architecture rtl;
