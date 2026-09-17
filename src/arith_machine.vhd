library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Maquina aritmetica do MIPS (VHDL-9)
--   instr -> reg_file (rs, rt) -> mux ula_src2 (rt / sign_ext / zero_ext) -> ULA
--   resultado da ULA e escrito em rd (rd_src = 0) ou rt (rd_src = 1)
entity arith_machine is
  port(
    instr     : in  std_logic_vector(31 downto 0);

    rd_src    : in  std_logic;
    wr_enable : in  std_logic;
    ula_src2  : in  std_logic_vector(1 downto 0);
    ula_op    : in  std_logic_vector(2 downto 0);

    clk       : in  std_logic;
    reset     : in  std_logic;

    overflow  : out std_logic;
    zero      : out std_logic;
    negative  : out std_logic;
    ula_out   : out std_logic_vector(31 downto 0)
  );
end entity arith_machine;

architecture rtl of arith_machine is

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

  component ULA is
    port (
      A             : in  std_logic_vector(31 downto 0);
      B             : in  std_logic_vector(31 downto 0);
      control       : in  std_logic_vector(2 downto 0);
      result        : out std_logic_vector(31 downto 0);
      flag_neg      : out std_logic;
      flag_zero     : out std_logic;
      flag_overflow : out std_logic
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

  signal rs_addr, rt_addr, rd_addr, write_addr : std_logic_vector(4 downto 0);
  signal imm16        : std_logic_vector(15 downto 0);
  signal sign_ext_out : std_logic_vector(31 downto 0);
  signal zero_ext_out : std_logic_vector(31 downto 0);
  signal reg_A_data   : std_logic_vector(31 downto 0);
  signal reg_B_data   : std_logic_vector(31 downto 0);
  signal ula_B_in     : std_logic_vector(31 downto 0);
  signal ula_out_sig  : std_logic_vector(31 downto 0);

begin

  rs_addr <= instr(25 downto 21);
  rt_addr <= instr(20 downto 16);
  rd_addr <= instr(15 downto 11);
  imm16   <= instr(15 downto 0);

  -- mux do endereco de escrita: rd_src = 0 -> rd (tipo R) ; rd_src = 1 -> rt (tipo I)
  write_addr <= rt_addr when rd_src = '1' else rd_addr;

  u_sign_ext : sign_extender
    port map(
      imm16        => imm16,
      sign_ext_imm => sign_ext_out
    );

  u_zero_ext : zero_extender
    port map(
      imm16        => imm16,
      zero_ext_imm => zero_ext_out
    );

  u_reg_file : reg_file
    port map(
      clk    => clk,
      rst    => reset,
      A_addr => rs_addr,
      B_addr => rt_addr,
      W_addr => write_addr,
      W_data => ula_out_sig,
      W_en   => wr_enable,
      A_data => reg_A_data,
      B_data => reg_B_data
    );

  -- mux da segunda entrada da ULA
  with ula_src2 select
    ula_B_in <= reg_B_data      when "00",
                sign_ext_out    when "01",
                zero_ext_out    when "10",
                (others => '0') when others;

  u_ula : ULA
    port map(
      A             => reg_A_data,
      B             => ula_B_in,
      control       => ula_op,
      result        => ula_out_sig,
      flag_neg      => negative,
      flag_zero     => zero,
      flag_overflow => overflow
    );

  ula_out <= ula_out_sig;

end architecture rtl;
