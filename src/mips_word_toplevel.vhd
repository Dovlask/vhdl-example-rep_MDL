library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- MIPS monociclo simplificado (somente word) -- APS-1-4
--
--  PC register -> ROM (instrucao) -> control_unit / reg_file / extensores
--  -> mux alu_src2 -> ULA -> RAM (dados) -> mux mem_read -> W_data do reg_file
--  nextPC escolhe o proximo PC (PC+4, branch, jump, jr) via control_type.
--
--  Mux do caminho de dados (nomes iguais aos do diagrama):
--    rd_src   : W_addr = rd (0) | rt (1)
--    alu_src2 : B da ULA = R[rt] (00) | SignExtImm (01) | ZeroExtImm (10)
--    mem_read : W_data = saida da ULA (0) | data_out da RAM (1)
--    control_type (dentro do nextPC): PC+4 | PC+4+BranchAddr | JumpAddr | R[rs]
entity mips_word_toplevel is
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;
    -- saidas para depuracao / visualizacao
    pc_out   : out std_logic_vector(31 downto 0);
    inst_out : out std_logic_vector(31 downto 0);
    alu_out  : out std_logic_vector(31 downto 0);
    except   : out std_logic
  );
end entity mips_word_toplevel;

architecture rtl of mips_word_toplevel is

  ------------------------------------------------------------------ componentes
  component pc_register is
    port(
      clk    : in  std_logic;
      reset  : in  std_logic;
      enable : in  std_logic;
      D      : in  std_logic_vector(31 downto 0);
      Q      : out std_logic_vector(31 downto 0)
    );
  end component;

  component nextPC is
    port(
      nextPC       : out std_logic_vector(31 downto 0);
      control_type : in  std_logic_vector(1 downto 0);
      pc           : in  std_logic_vector(31 downto 0);
      intruction   : in  std_logic_vector(25 downto 0);
      branch_addr  : in  std_logic_vector(31 downto 0);
      a_data       : in  std_logic_vector(31 downto 0)
    );
  end component;

  component mips_rom is
    generic(
      dataWidth : natural := 32;
      addrWidth : natural := 10
    );
    port(
      addr : in  std_logic_vector(addrWidth-1 downto 0);
      data : out std_logic_vector(dataWidth-1 downto 0)
    );
  end component;

  component mips_ram is
    generic(
      dataWidth       : natural := 32;
      addrWidth       : natural := 32;
      memoryAddrWidth : natural := 10
    );
    port(
      clk      : in  std_logic;
      addr     : in  std_logic_vector(addrWidth-1 downto 0);
      data_in  : in  std_logic_vector(dataWidth-1 downto 0);
      data_out : out std_logic_vector(dataWidth-1 downto 0);
      word_we  : in  std_logic;
      reset    : in  std_logic
    );
  end component;

  component control_unit is
    port(
      zero         : in  std_logic;
      opcode       : in  std_logic_vector(5 downto 0);
      func         : in  std_logic_vector(5 downto 0);
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
  end component;

  component reg_file is
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
  end component;

  component sign_extender is
    port(
      imm16        : in  std_logic_vector(15 downto 0);
      sign_ext_imm : out std_logic_vector(31 downto 0)
    );
  end component;

  component zero_extender is
    port(
      imm16        : in  std_logic_vector(15 downto 0);
      zero_ext_imm : out std_logic_vector(31 downto 0)
    );
  end component;

  component shift_left2 is
    port(
      din  : in  std_logic_vector(31 downto 0);
      dout : out std_logic_vector(31 downto 0)
    );
  end component;

  component ULA is
    port(
      A             : in  std_logic_vector(31 downto 0);
      B             : in  std_logic_vector(31 downto 0);
      control       : in  std_logic_vector(2 downto 0);
      result        : out std_logic_vector(31 downto 0);
      flag_neg      : out std_logic;
      flag_zero     : out std_logic;
      flag_overflow : out std_logic
    );
  end component;

  -------------------------------------------------------------------- sinais
  -- PC
  signal pc, next_pc      : std_logic_vector(31 downto 0);
  -- instrucao e campos
  signal inst             : std_logic_vector(31 downto 0);
  signal opcode, funct    : std_logic_vector(5 downto 0);
  signal rs, rt, rd       : std_logic_vector(4 downto 0);
  signal imm16            : std_logic_vector(15 downto 0);
  -- controle
  signal alu_op           : std_logic_vector(2 downto 0);
  signal write_enable     : std_logic;
  signal rd_src           : std_logic;
  signal alu_src2         : std_logic_vector(1 downto 0);
  signal control_type     : std_logic_vector(1 downto 0);
  signal lui, slt         : std_logic;
  signal byte_load        : std_logic;
  signal word_we, byte_we : std_logic;
  signal mem_read         : std_logic;
  -- caminho de dados
  signal w_addr           : std_logic_vector(4 downto 0);
  signal w_data           : std_logic_vector(31 downto 0);
  signal A_data, B_data   : std_logic_vector(31 downto 0);
  signal sign_ext_imm     : std_logic_vector(31 downto 0);
  signal zero_ext_imm     : std_logic_vector(31 downto 0);
  signal branch_addr      : std_logic_vector(31 downto 0);
  signal alu_B            : std_logic_vector(31 downto 0);
  signal alu_result       : std_logic_vector(31 downto 0);
  signal zero, negative   : std_logic;
  signal overflow         : std_logic;
  signal mem_data_out     : std_logic_vector(31 downto 0);

begin

  ------------------------------------------------------------------ PC / fetch
  u_pc : pc_register
    port map(
      clk    => clk,
      reset  => reset,
      enable => '1',
      D      => next_pc,
      Q      => pc
    );

  -- ROM de 1024 palavras: endereco de palavra = PC(11 downto 2)
  u_rom : mips_rom
    generic map(dataWidth => 32, addrWidth => 10)
    port map(
      addr => pc(11 downto 2),
      data => inst
    );

  -- campos da instrucao
  opcode <= inst(31 downto 26);
  rs     <= inst(25 downto 21);
  rt     <= inst(20 downto 16);
  rd     <= inst(15 downto 11);
  imm16  <= inst(15 downto 0);
  funct  <= inst(5 downto 0);

  ------------------------------------------------------------------ decoder
  u_control : control_unit
    port map(
      zero         => zero,
      opcode       => opcode,
      func         => funct,
      ula_op       => alu_op,
      write_enable => write_enable,
      rd_src       => rd_src,
      alu_src2     => alu_src2,
      control_type => control_type,
      lui          => lui,
      slt          => slt,
      byte_load    => byte_load,
      word_we      => word_we,
      byte_we      => byte_we,
      mem_read     => mem_read,
      except       => except
    );

  ------------------------------------------------------------------ banco de registradores
  -- mux rd_src: 0 -> rd (tipo R) | 1 -> rt (tipo I)
  w_addr <= rt when rd_src = '1' else rd;

  u_reg_file : reg_file
    port map(
      clk    => clk,
      rst    => reset,
      A_addr => rs,
      B_addr => rt,
      W_addr => w_addr,
      W_data => w_data,
      W_en   => write_enable,
      A_data => A_data,
      B_data => B_data
    );

  ------------------------------------------------------------------ imediatos
  u_sign_ext : sign_extender
    port map(
      imm16        => imm16,
      sign_ext_imm => sign_ext_imm
    );

  u_zero_ext : zero_extender
    port map(
      imm16        => imm16,
      zero_ext_imm => zero_ext_imm
    );

  -- BranchAddr = SignExtImm << 2
  u_shift2 : shift_left2
    port map(
      din  => sign_ext_imm,
      dout => branch_addr
    );

  ------------------------------------------------------------------ ULA
  -- mux alu_src2: 00 -> R[rt] | 01 -> SignExtImm | 10 -> ZeroExtImm
  with alu_src2 select
    alu_B <= B_data          when "00",
             sign_ext_imm    when "01",
             zero_ext_imm    when "10",
             (others => '0') when others;

  u_ula : ULA
    port map(
      A             => A_data,
      B             => alu_B,
      control       => alu_op,
      result        => alu_result,
      flag_neg      => negative,
      flag_zero     => zero,
      flag_overflow => overflow
    );

  ------------------------------------------------------------------ memoria de dados
  u_ram : mips_ram
    generic map(dataWidth => 32, addrWidth => 32, memoryAddrWidth => 10)
    port map(
      clk      => clk,
      addr     => alu_result,
      data_in  => B_data,
      data_out => mem_data_out,
      word_we  => word_we,
      reset    => reset
    );

  -- mux mem_read: 0 -> resultado da ULA | 1 -> dado lido da RAM
  w_data <= mem_data_out when mem_read = '1' else alu_result;

  ------------------------------------------------------------------ proximo PC
  u_next_pc : nextPC
    port map(
      nextPC       => next_pc,
      control_type => control_type,
      pc           => pc,
      intruction   => inst(25 downto 0),
      branch_addr  => branch_addr,
      a_data       => A_data
    );

  ------------------------------------------------------------------ saidas
  pc_out   <= pc;
  inst_out <= inst;
  alu_out  <= alu_result;

end architecture rtl;
