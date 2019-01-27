-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 27.1.2019 20:45:07 GMT

library ieee;
use ieee.std_logic_1164.all;

entity int_line_mux_tb is
end int_line_mux_tb;

architecture tb of int_line_mux_tb is

    component int_line_mux
        port (clk           : in std_logic;
              reset         : in std_logic;
              ack           : in std_logic;
              config        : in std_logic_vector (31 downto 0);
              int_lines_in  : in std_logic_vector (7 downto 0);
              out_level     : out std_logic_vector (2 downto 0);
              int_lines_out : out std_logic_vector (7 downto 0));
    end component;

    signal clk           : std_logic;
    signal reset         : std_logic;
    signal ack           : std_logic;
    signal config        : std_logic_vector (31 downto 0);
    signal int_lines_in  : std_logic_vector (7 downto 0);
    signal out_level     : std_logic_vector (2 downto 0);
    signal int_lines_out : std_logic_vector (7 downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : int_line_mux
    port map (clk           => clk,
              reset         => reset,
              ack           => ack,
              config        => config,
              int_lines_in  => int_lines_in,
              out_level     => out_level,
              int_lines_out => int_lines_out);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        ack <= '0';
        config <= (others => '0');
        int_lines_in <= (others => '0');

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- EDIT Add stimuli here
        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_int_line_mux_tb of int_line_mux_tb is
    for tb
    end for;
end cfg_int_line_mux_tb;
