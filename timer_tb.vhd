-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 21.1.2019 22:17:27 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_tb is
end timer_tb;

architecture tb of timer_tb is

    component timer
        generic (WIDTH: integer;
                 CLK_PER_PERIOD: integer);
        port (clk   : in std_logic;
              reset : in std_logic;
              value : in unsigned (WIDTH - 1 downto 0);
              ack   : in std_logic;
              int   : out std_logic);
    end component;

    signal clk   : std_logic;
    signal reset : std_logic;
    signal value : unsigned (31 downto 0);
    signal ack   : std_logic;
    signal int   : std_logic;

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : timer
    generic map (WIDTH => 32, CLK_PER_PERIOD => 1)
    port map (clk   => clk,
              reset => reset,
              value => value,
              ack   => ack,
              int   => int);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        value <= to_unsigned(5, 32);
        ack <= '0';

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        value <= to_unsigned(0, 32);

        -- EDIT Add stimuli here
        wait for 6 * TbPeriod;
        assert int = '1';

        ack <= '1';
        wait for TbPeriod;
        ack <= '0';
        assert int = '0';

        wait for 6 * TbPeriod;
        assert int = '1';
        ack <= '1';
        wait for TbPeriod;
        assert int = '0';

        ack <= '0';
        wait for TbPeriod;
        assert int = '0';

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        reset <= '1' ;
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_timer_tb of timer_tb is
    for tb
    end for;
end cfg_timer_tb;
