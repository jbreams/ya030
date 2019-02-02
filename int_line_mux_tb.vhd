-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 2.2.2019 19:41:40 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_line_mux_tb is
end int_line_mux_tb;

architecture tb of int_line_mux_tb is

    component int_line_mux
        port (clk           : in std_logic;
              reset         : in std_logic;
              enable        : in std_logic_vector (7 downto 0);
              clear         : in std_logic;
              int_lines_in  : in std_logic_vector (7 downto 0);
              int_lines_out : out std_logic_vector (7 downto 0);
              int_out       : out std_logic);
    end component;

    signal clk           : std_logic;
    signal reset         : std_logic;
    signal enable        : std_logic_vector (7 downto 0);
    signal clear         : std_logic;
    signal int_lines_in  : std_logic_vector (7 downto 0);
    signal int_lines_out : std_logic_vector (7 downto 0);
    signal int_out       : std_logic;

    constant TbPeriod : time := 5 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : int_line_mux
    port map (clk           => clk,
              reset         => reset,
              enable        => enable,
              clear         => clear,
              int_lines_in  => int_lines_in,
              int_lines_out => int_lines_out,
              int_out       => int_out);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        enable <= "11111111";
        clear <= '0';
        int_lines_in <= "00000000";

        reset <= '1';
        wait for 5 ns;
        reset <= '0';
        wait for 5 ns;

        assert int_out = '0';
        assert int_lines_out = "00000000";

        int_lines_in <= "00010001";

        wait for TbPeriod * 2;

        assert int_out = '1';
        assert int_lines_out = "00010001";

        clear <= '1';

        wait for TbPeriod * 2;

        assert int_lines_out = "00000000";
        assert int_out = '0';

        clear <= '0';
        enable <= "00001111";

        wait for TbPeriod / 2;
        int_lines_in <= "10101010";

        wait for TbPeriod;
        assert int_lines_out = "00001011";
        assert int_out = '1';

        clear <= '1';

        wait for TbPeriod;
        int_lines_in <= "00000000";
        clear <= '0';

        wait for TbPeriod * 2;

        assert int_lines_out = "00000000";
        assert int_out = '0';

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
