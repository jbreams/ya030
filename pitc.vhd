library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pitc is
generic (
    TIMER_PERIOD_WIDTH : integer := 18;
    CLK_PER_US : unsigned(TIMER_PERIOD_WIDTH - 1 downto 0) := to_unsigned(15, TIMER_PERIOD_WIDTH));
port (
    clk : in std_logic;
    reset : in std_logic;
    cs : in std_logic;
    rw : in std_logic;
    addr : in std_logic_vector(2 downto 0);
    data : inout std_logic_vector(7 downto 0);
    ext_int_lines_in : in std_logic_vector(5 downto 0);
    int_out : out std_logic;
    dtack : out std_logic
);
end pitc;

architecture behavioral of pitc is

component period_timer is
    generic (WIDTH: integer;
             PERIOD_WIDTH: integer);
    port (
        clk : in std_logic;
        reset : in std_logic;
        period : in unsigned(PERIOD_WIDTH - 1 downto 0);
        value : in unsigned(WIDTH - 1 downto 0);
        ack : in std_logic;
        int : out std_logic);
end component;

component int_line_mux is
    generic (WIDTH : integer := 8);    
    port(
        clk : in std_logic;
        reset : in std_logic;
        enable : in std_logic_vector(WIDTH - 1 downto 0);
        clear : in std_logic;
        int_lines_in : in std_logic_vector(WIDTH - 1 downto 0);
        int_lines_out : out std_logic_vector(WIDTH - 1 downto 0);
        int_out : out std_logic);
    end component;

constant CLK_PER_MS : unsigned(TIMER_PERIOD_WIDTH - 1 downto 0) := CLK_PER_US * 1000;
constant CLK_PER_SEC : unsigned(TIMER_PERIOD_WIDTH - 1 downto 0) := CLK_PER_MS * 1000;

constant ADDR_INT_READY : integer := 0;
constant ADDR_INT_ENABLE : integer := 1;
constant ADDR_TIMERA_CONFIG : integer := 2;
constant ADDR_TIMERA_VALUE : integer := 3;
constant ADDR_TIMERB_CONFIG : integer := 4;
constant ADDR_TIMERB_VALUE : integer := 5;
constant ADDR_MAX : integer := 6;


type REGISTERS_TYPE is array (0 to ADDR_MAX) of std_logic_vector(7 downto 0);
signal registers : REGISTERS_TYPE;

signal int_clear : std_logic;
signal int_lines_in : std_logic_vector(7 downto 0);

signal timera_reset : std_logic;
signal timera_period : unsigned(TIMER_PERIOD_WIDTH downto 0);
signal timera_ack : std_logic;
signal timera_int : std_logic;

signal timerb_reset : std_logic;
signal timerb_period : unsigned(TIMER_PERIOD_WIDTH downto 0);
signal timerb_ack : std_logic;
signal timerb_int : std_logic;

begin

timera : component period_timer
    generic map(WIDTH => 8, PERIOD_WIDTH => TIMER_PERIOD_WIDTH)
    port map(clk => clk,
             reset => timera_reset,
             period => timera_period,
             value => unsigned(registers(ADDR_TIMERA_VALUE)),
             ack => timera_ack,
             int => timera_int);

timerb : component period_timer
    generic map(WIDTH => 8, PERIOD_WIDTH => TIMER_PERIOD_WIDTH)
    port map(clk => clk,
             reset => timerb_reset,
             period => timerb_period,
             value => unsigned(registers(ADDR_TIMERB_VALUE)),
             ack => timerb_ack,
             int => timerb_int);

int_mux : component int_line_mux
    generic map(WIDTH => 8)
    port map(clk => clk,
             reset => reset,
             enable => std_logic_vector(registers(ADDR_INT_ENABLE)),
             clear => int_clear,
             int_lines_in => int_lines_in,
             int_lines_out => registers(ADDR_INT_READY),
             int_out => int_out);

int_lines_in <= (ext_int_lines_in(5) &
                 ext_int_lines_in(4) &
                 ext_int_lines_in(3) &
                 ext_int_lines_in(2) &
                 ext_int_lines_in(1) &
                 ext_int_lines_in(0) &
                 timera_int &
                 timerb_int);

cpu_proc : process(reset, clk, rw, cs, addr, data) is
    variable unsigned_addr : integer;
    variable timer_config : integer;
begin
    unsigned_addr := to_integer(unsigned(addr));
    if (reset = '1') then
        timera_reset <= '1';
        timerb_reset <= '1';
    elsif (clk'event and clk = '0') then
        timera_reset <= '0';
        timerb_reset <= '0';
        if (cs = '1') then
            case rw is
                when '1' => -- Read cycle
                    data <= registers(unsigned_addr);
                    dtack <= '1';
                when '0' => -- Write cycle
                    registers(unsigned_addr) <= data;
                    case unsigned_addr is
                        when ADDR_INT_READY =>
                            int_clear <= '1';

                        when ADDR_TIMERA_CONFIG =>
                            timer_config := to_integer(unsigned(
                                registers(ADDR_TIMERA_CONFIG)(3 downto 0)));
                            case timer_config is
                                when 1 => -- When the config is set to zero, the period is clk.
                                    timera_period <= to_unsigned(1, TIMER_PERIOD_WIDTH);
                                when 2 =>
                                    timera_period <= CLK_PER_US;
                                when 3 =>
                                    timera_period <= CLK_PER_MS;
                                when 4 =>
                                    timera_period <= CLK_PER_SEC;
                                when others =>
                                    timera_period <= to_unsigned(0, TIMER_PERIOD_WIDTH);
                            end case;

                            timera_ack <= registers(ADDR_TIMERA_CONFIG)(7);
                            timera_reset <= '1';

                        when ADDR_TIMERA_VALUE =>
                            timera_ack <= registers(ADDR_TIMERA_CONFIG)(7);
                            timera_reset <= '1';

                        when ADDR_TIMERB_CONFIG =>
                            timer_config := to_integer(unsigned(
                                registers(ADDR_TIMERB_CONFIG)(3 downto 0)));
                            case timer_config is
                                when 1 => -- When the config is set to zero, the period is clk.
                                    timerb_period <= to_unsigned(1, TIMER_PERIOD_WIDTH);
                                when 2 =>
                                    timerb_period <= CLK_PER_US;
                                when 3 =>
                                    timerb_period <= CLK_PER_MS;
                                when 4 =>
                                    timerb_period <= CLK_PER_SEC;
                                when others =>
                                    timerb_period <= to_unsigned(0, TIMER_PERIOD_WIDTH);
                            end case;

                            timerb_ack <= registers(ADDR_TIMERB_CONFIG)(7);
                            timerb_reset <= '1';

                        when ADDR_TIMERB_VALUE =>
                            timerb_ack <= registers(ADDR_TIMERB_CONFIG)(7);
                            timerb_reset <= '1';
                        when others =>
                    end case;
                when others =>
            end case;
        end if;
    end if;
end process;

end behavioral;
