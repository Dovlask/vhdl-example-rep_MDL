library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Toplevel para validar a maquina aritmetica na placa (APS-1-3.5)
--
--   KEY(0) : avanca para a proxima instrucao (cnt + 1)
--   KEY(1) : reset (zera banco de registradores e cnt)
--   HEX0   : cnt atual (numero da instrucao)
--   LEDR   : ula_out(9 downto 0)
--   HEX1   : flags -> bit2 = overflow, bit1 = negative, bit0 = zero
--   HEX5..HEX2 : ula_out(15 downto 0) em hexadecimal
--
-- Programa (cada instrucao escreve em um registrador diferente das fontes,
-- entao pode ser executada varias vezes seguidas sem mudar o resultado):
--   0: addi $1, $0, 10     -> 10          (0x0000000A)
--   1: addi $2, $0, 3      -> 3           (0x00000003)
--   2: add  $3, $1, $2     -> 13          (0x0000000D)
--   3: sub  $4, $1, $2     -> 7           (0x00000007)
--   4: and  $5, $1, $2     -> 2           (0x00000002)
--   5: or   $6, $1, $2     -> 11          (0x0000000B)
--   6: xor  $7, $1, $2     -> 9           (0x00000009)
--   7: nor  $8, $1, $2     -> 0xFFFFFFF4  (negative)
--   8: sub  $9, $2, $1     -> -7          (0xFFFFFFF9, negative)
--   9: ori  $10, $1, 0xF0  -> 250         (0x000000FA, zero extend)
--   A: addi $11, $0, -1    -> -1          (0xFFFFFFFF, sign extend)
--   B: sub  $12, $1, $1    -> 0           (zero)
entity toplevel_mips is
  port(
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    SW       : in  std_logic_vector(9 downto 0);
    LEDR     : out std_logic_vector(9 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0);
    HEX3     : out std_logic_vector(6 downto 0);
    HEX4     : out std_logic_vector(6 downto 0);
    HEX5     : out std_logic_vector(6 downto 0)
  );
end entity toplevel_mips;

architecture rtl of toplevel_mips is

  component arith_machine is
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
  end component;

  component hex7seg is
    port(
      hex : in  std_logic_vector(3 downto 0);
      seg : out std_logic_vector(6 downto 0)
    );
  end component;

  constant N_INST  : integer := 12;
  constant DEB_MAX : integer := 500000;  -- ~10 ms @ 50 MHz

  signal reset      : std_logic;
  signal key_sync   : std_logic_vector(1 downto 0) := (others => '0');
  signal key_stable : std_logic := '0';
  signal key_prev   : std_logic := '0';
  signal deb_cnt    : integer range 0 to DEB_MAX := 0;
  signal cnt        : integer range 0 to N_INST - 1 := 0;

  signal instr      : std_logic_vector(31 downto 0);
  signal rd_src     : std_logic;
  signal wr_enable  : std_logic;
  signal ula_src2   : std_logic_vector(1 downto 0);
  signal ula_op     : std_logic_vector(2 downto 0);

  signal overflow   : std_logic;
  signal zero       : std_logic;
  signal negative   : std_logic;
  signal ula_out    : std_logic_vector(31 downto 0);

  signal cnt_hex    : std_logic_vector(3 downto 0);
  signal flags_hex  : std_logic_vector(3 downto 0);

begin

  reset <= not KEY(1);  -- botoes da placa sao ativos em 0

  -- botao -> cnt (sincronizador + debounce + detector de borda)
  process(CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      key_sync <= key_sync(0) & (not KEY(0));

      if key_sync(1) /= key_stable then
        if deb_cnt = DEB_MAX then
          key_stable <= key_sync(1);
          deb_cnt    <= 0;
        else
          deb_cnt <= deb_cnt + 1;
        end if;
      else
        deb_cnt <= 0;
      end if;

      key_prev <= key_stable;

      if reset = '1' then
        cnt <= 0;
      elsif key_stable = '1' and key_prev = '0' then
        if cnt = N_INST - 1 then
          cnt <= 0;
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;

  -- IP/process que gera os estimulos de teste (instrucao + sinais de controle)
  process(cnt)
  begin
    rd_src    <= '0';
    wr_enable <= '1';
    ula_src2  <= "00";
    ula_op    <= "010";
    case cnt is
      when 0 =>  instr <= x"2001000A"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "010"; -- addi $1, $0, 10
      when 1 =>  instr <= x"20020003"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "010"; -- addi $2, $0, 3
      when 2 =>  instr <= x"00221820"; ula_op <= "010";                                  -- add  $3, $1, $2
      when 3 =>  instr <= x"00222022"; ula_op <= "011";                                  -- sub  $4, $1, $2
      when 4 =>  instr <= x"00222824"; ula_op <= "100";                                  -- and  $5, $1, $2
      when 5 =>  instr <= x"00223025"; ula_op <= "101";                                  -- or   $6, $1, $2
      when 6 =>  instr <= x"00223826"; ula_op <= "111";                                  -- xor  $7, $1, $2
      when 7 =>  instr <= x"00224027"; ula_op <= "110";                                  -- nor  $8, $1, $2
      when 8 =>  instr <= x"00414822"; ula_op <= "011";                                  -- sub  $9, $2, $1
      when 9 =>  instr <= x"342A00F0"; rd_src <= '1'; ula_src2 <= "10"; ula_op <= "101"; -- ori  $10, $1, 0xF0
      when 10 => instr <= x"200BFFFF"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "010"; -- addi $11, $0, -1
      when others =>
                 instr <= x"00216022"; ula_op <= "011";                                  -- sub  $12, $1, $1
    end case;
  end process;

  u_arith : arith_machine
    port map(
      instr     => instr,
      rd_src    => rd_src,
      wr_enable => wr_enable,
      ula_src2  => ula_src2,
      ula_op    => ula_op,
      clk       => CLOCK_50,
      reset     => reset,
      overflow  => overflow,
      zero      => zero,
      negative  => negative,
      ula_out   => ula_out
    );

  LEDR <= ula_out(9 downto 0);

  cnt_hex   <= std_logic_vector(to_unsigned(cnt, 4));
  flags_hex <= '0' & overflow & negative & zero;

  u_hex0 : hex7seg port map(hex => cnt_hex,               seg => HEX0);
  u_hex1 : hex7seg port map(hex => flags_hex,             seg => HEX1);
  u_hex2 : hex7seg port map(hex => ula_out(3 downto 0),   seg => HEX2);
  u_hex3 : hex7seg port map(hex => ula_out(7 downto 4),   seg => HEX3);
  u_hex4 : hex7seg port map(hex => ula_out(11 downto 8),  seg => HEX4);
  u_hex5 : hex7seg port map(hex => ula_out(15 downto 12), seg => HEX5);

end architecture rtl;
