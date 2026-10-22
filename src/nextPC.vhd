library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Calculo do proximo PC (VHDL-10.1)
--   control_type: 00 -> PC + 4
--                 01 -> PC + 4 + BranchAddr   (branch tomado)
--                 10 -> {PC+4[31:28], inst[25:0], 00}   (j)
--                 11 -> R[rs]                  (jr)
-- No diagrama as duas somas sao feitas com ULAs; aqui usamos somas do numeric_std.
entity nextPC is
port(
	nextPC       : out std_logic_vector(31 downto 0);
	control_type : in  std_logic_vector(1 downto 0);
	pc           : in  std_logic_vector(31 downto 0);
	intruction   : in  std_logic_vector(25 downto 0);
	branch_addr  : in  std_logic_vector(31 downto 0);
	a_data       : in  std_logic_vector(31 downto 0)
);
end nextPC;

architecture behv1 of nextPC is
	signal pc4 : std_logic_vector(31 downto 0);
begin
	pc4 <= std_logic_vector(unsigned(pc) + 4);

	with control_type select
		nextPC <= pc4                                                   when "00",
		          std_logic_vector(unsigned(pc4) + unsigned(branch_addr)) when "01",
		          pc4(31 downto 28) & intruction & "00"                 when "10",
		          a_data                                                when others;
end behv1;
