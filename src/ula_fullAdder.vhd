library ieee;
use ieee.std_logic_1164.all;

-- Somador completo de 1 bit (Revisao-6.5)
entity ula_fullAdder is
  port(
    a, b, cin : in  std_logic;
    s         : out std_logic;
    cout      : out std_logic
  );
end entity ula_fullAdder;

architecture rtl of ula_fullAdder is
begin
  s    <= a xor b xor cin;
  cout <= (a and b) or (cin and (a xor b));
end architecture rtl;
