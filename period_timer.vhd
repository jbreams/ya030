library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity period_timer is
generic (WIDTH: integer;
         PERIOD_WIDTH: integer);
port (
    clk : in std_logic;
    reset : in std_logic;
    period_value : in unsigned(PERIOD_WIDTH - 1 downto 0);
    value : in unsigned(WIDTH - 1 downto 0);
    ack : in std_logic;
    int : out std_logic
);
end period_timer;

architecture behavioral of period_timer is
    component timer
        generic (WIDTH: integer);
        port (clk   : in std_logic;
              reset : in std_logic;
              value : in unsigned (WIDTH - 1 downto 0);
              ack   : in std_logic;
              int   : out std_logic);
    end component;

    signal period : unsigned(PERIOD_WIDTH - 1 downto 0);
    signal period_int : std_logic;
    signal period_ack : std_logic;

begin

    int_period_timer : timer
    generic map (WIDTH => PERIOD_WIDTH)
    port map (clk => clk,
              reset => reset,
              value => period,
              ack => period_ack,
              int => period_int);

    timer_proc : process(period_int, reset, value, ack) is
    variable target : unsigned (WIDTH - 1 downto 0) := to_unsigned(0, WIDTH);
    variable counter : unsigned (WIDTH - 1 downto 0) := to_unsigned(0, WIDTH);
    variable done : boolean := false;
    begin
        if (reset = '1') then
            target := value;
            counter := to_unsigned(0, WIDTH);
            period <= period_value;
            done := false when target /= to_unsigned(0, WIDTH) else true;
            int <= '0';
        elsif (not done) then
            if (period_int'event and period_int = '1') then
                counter := counter + 1;
                period_ack <= '1';
                if (counter = target) then
                    int <= '1';
                    counter := to_unsigned(0, WIDTH);
                    done := true;
                end if;
            elsif (period_ack = '1') then
                period_ack <= '0';
            end if;
        elsif (clk'event) then
            if (clk = '0' and ack = '1') then
                done := false when target /= to_unsigned(0, WIDTH) else true;
                period_ack <= '1';
                int <= '0';
            end if;
        end if;
    end process;

end behavioral;
