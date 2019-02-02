-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 27.1.2019 16:05:44 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_line_tb is
end int_line_tb;

architecture tb of int_line_tb is

    component int_line
        port (clk           : in std_logic;
              reset         : in std_logic;
              clear         : in std_logic;
              enable        : in std_logic;
              int_in        : in std_logic;
              int_out       : out std_logic);
    end component;

    signal clk           : std_logic;
    signal reset         : std_logic;
    signal clear         : std_logic;
    signal int_in        : std_logic;
    signal int_out       : std_logic;
    signal enable        : std_logic;

    constant TbPeriod : time := 5 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : int_line
    port map (clk           => clk,
              reset         => reset,
              clear         => clear,
              enable        => enable,
              int_in        => int_in,
              int_out       => int_out);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        clear <= '0';
        int_in <= '0';
        enable <= '1';

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 10 ns;

        wait for 3 ns;
        int_in <= '1';
        wait for 1 ns;
        int_in <= '0';
        wait for 1 ns;

        wait for TbPeriod;

        assert int_out = '1';

        wait for TbPeriod;
        
        clear <= '1';
        wait for TbPeriod;
        clear <= '0';

        assert int_out = '0';

        wait for 2 ns;
        int_in <= '1';
        wait for 1 ns;
        int_in <= '0';
        wait for 7 ns;

        assert int_out = '1';

        clear <= '1';
        wait for TbPeriod;
        clear <= '0';

        assert int_out = '0';

        wait for 3 ns;

        enable <= '0';
        int_in <= '1';

        wait for 3 ns;

        int_in <= '0';
        wait for 7 ns;

        assert int_out = '0';


        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_int_line_tb of int_line_tb is
    for tb
    end for;
end cfg_int_line_tb;
