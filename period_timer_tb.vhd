-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 7.2.2019 21:34:12 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity period_timer_tb is
end period_timer_tb;

architecture tb of period_timer_tb is

    component period_timer
        generic (WIDTH: integer;
                 PERIOD_WIDTH: integer);
        port (clk          : in std_logic;
              reset        : in std_logic;
              period       : in unsigned (PERIOD_WIDTH - 1 downto 0);
              value        : in unsigned (width - 1 downto 0);
              ack          : in std_logic;
              int          : out std_logic);
    end component;

    signal clk          : std_logic;
    signal reset        : std_logic;
    signal period_value : unsigned (15 downto 0);
    signal value        : unsigned (7 downto 0);
    signal ack          : std_logic;
    signal int          : std_logic;

    constant TbPeriod : time := 100 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

    --- 1us / 100ns = 10
    constant ClkPerUs : unsigned(15 downto 0) := to_unsigned(10, 16);

begin

    dut : period_timer
    generic map(WIDTH => 8,
                PERIOD_WIDTH => 16)
    port map (clk          => clk,
              reset        => reset,
              period       => period_value,
              value        => value,
              ack          => ack,
              int          => int);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        period_value <= ClkPerUs;
        value <= to_unsigned(3, 8);
        ack <= '0';

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        ack <= '1';
        wait for TbPeriod;
        ack <= '0';

        wait for 3 us;
        wait for TbPeriod;
        assert int = '1';

        wait for TbPeriod;
        ack <= '1';
        wait for TbPeriod;
        assert int = '0';
        ack <= '0';
        wait for TbPeriod;
        wait for 3 us;

        assert int = '1';

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_period_timer_tb of period_timer_tb is
    for tb
    end for;
end cfg_period_timer_tb;
