library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Unidade de controle (decoder) do MIPS -- versao "word" da APS-1-4
--
-- Entradas: opcode = inst(31 downto 26), func = inst(5 downto 0), zero = flag da ULA
--
-- Instrucoes suportadas pelo caminho de dados do diagrama da APS-1-4:
--   tipo R : add, addu, sub, subu, and, or, xor, nor, jr
--   tipo I : addi, addiu, andi, ori, xori, lw, sw, beq, bne
--   tipo J : j
-- Qualquer outra instrucao -> except = '1' e nada e escrito (write_enable = '0',
-- word_we = '0'), para nao alterar o estado da CPU.
--
-- lui / slt / byte_load / byte_we existem na interface (diagrama), mas o caminho
-- de dados desta versao ainda nao tem os mux correspondentes; por isso ficam em '0'
-- e as instrucoes lui/slt/slti/lb/lbu/sb sao tratadas como invalidas por enquanto.
--
-- ula_op (mesma codificacao da nossa ULA):
--   010 soma | 011 subtracao | 100 AND | 101 OR | 110 NOR | 111 XOR
-- alu_src2: 00 R[rt] | 01 SignExtImm | 10 ZeroExtImm
-- control_type (mux do proximo PC): 00 PC+4 | 01 PC+4+BranchAddr | 10 JumpAddr | 11 R[rs]
entity control_unit is
port(
	zero         : in  std_logic;
	opcode       : in  std_logic_vector(5 downto 0);
	func         : in  std_logic_vector(5 downto 0);

	-- sinais a serem controlados:
	ula_op       : out std_logic_vector(2 downto 0);
	write_enable : out std_logic;
	rd_src       : out std_logic;
	alu_src2     : out std_logic_vector(1 downto 0);
	control_type : out std_logic_vector(1 downto 0);
	lui          : out std_logic;
	slt          : out std_logic;
	byte_load    : out std_logic;
	word_we      : out std_logic;
	byte_we      : out std_logic;
	mem_read     : out std_logic;
	except       : out std_logic
);
end control_unit;

architecture behv1 of control_unit is
begin

	process(opcode, func, zero)
	begin
		-- valores padrao: instrucao invalida -> nao altera nada na CPU
		ula_op       <= "010";
		write_enable <= '0';
		rd_src       <= '0';
		alu_src2     <= "00";
		control_type <= "00";
		lui          <= '0';
		slt          <= '0';
		byte_load    <= '0';
		word_we      <= '0';
		byte_we      <= '0';
		mem_read     <= '0';
		except       <= '1';

		case opcode is
			-------------------------------------------------------------- tipo R
			when "000000" =>
				case func is
					when "100000" | "100001" =>                    -- add / addu
						ula_op <= "010"; write_enable <= '1'; except <= '0';
					when "100010" | "100011" =>                    -- sub / subu
						ula_op <= "011"; write_enable <= '1'; except <= '0';
					when "100100" =>                               -- and
						ula_op <= "100"; write_enable <= '1'; except <= '0';
					when "100101" =>                               -- or
						ula_op <= "101"; write_enable <= '1'; except <= '0';
					when "100110" =>                               -- xor
						ula_op <= "111"; write_enable <= '1'; except <= '0';
					when "100111" =>                               -- nor
						ula_op <= "110"; write_enable <= '1'; except <= '0';
					when "001000" =>                               -- jr: PC = R[rs]
						control_type <= "11"; except <= '0';
					when others =>
						null;                                      -- invalida
				end case;

			-------------------------------------------------------------- tipo I
			when "001000" | "001001" =>                            -- addi / addiu (SignExtImm)
				ula_op <= "010"; alu_src2 <= "01"; rd_src <= '1'; write_enable <= '1'; except <= '0';
			when "001100" =>                                       -- andi (ZeroExtImm)
				ula_op <= "100"; alu_src2 <= "10"; rd_src <= '1'; write_enable <= '1'; except <= '0';
			when "001101" =>                                       -- ori  (ZeroExtImm)
				ula_op <= "101"; alu_src2 <= "10"; rd_src <= '1'; write_enable <= '1'; except <= '0';
			when "001110" =>                                       -- xori (ZeroExtImm)
				ula_op <= "111"; alu_src2 <= "10"; rd_src <= '1'; write_enable <= '1'; except <= '0';
			when "100011" =>                                       -- lw: R[rt] = M[R[rs] + SignExtImm]
				ula_op <= "010"; alu_src2 <= "01"; rd_src <= '1'; write_enable <= '1';
				mem_read <= '1'; except <= '0';
			when "101011" =>                                       -- sw: M[R[rs] + SignExtImm] = R[rt]
				ula_op <= "010"; alu_src2 <= "01"; word_we <= '1'; except <= '0';
			when "000100" =>                                       -- beq: R[rs] - R[rt] == 0 ?
				ula_op <= "011"; alu_src2 <= "00"; except <= '0';
				if zero = '1' then control_type <= "01"; end if;
			when "000101" =>                                       -- bne: R[rs] - R[rt] != 0 ?
				ula_op <= "011"; alu_src2 <= "00"; except <= '0';
				if zero = '0' then control_type <= "01"; end if;

			-------------------------------------------------------------- tipo J
			when "000010" =>                                       -- j: PC = JumpAddr
				control_type <= "10"; except <= '0';

			when others =>
				null;                                              -- invalida
		end case;
	end process;

end behv1;
