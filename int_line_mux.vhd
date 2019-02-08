library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_line_mux is
generic (WIDTH : integer := 8);    
port(
    clk : in std_logic;
    reset : in std_logic;
    enable : in std_logic_vector(WIDTH - 1 downto 0);
    clear : in std_logic;
    int_lines_in : in std_logic_vector(WIDTH - 1 downto 0);
    int_lines_out : out std_logic_vector(WIDTH - 1 downto 0);
    int_out : out std_logic);
end int_line_mux;

architecture behavioral of int_line_mux is

component int_line
    port (clk           : in std_logic;
          reset         : in std_logic;
          clear         : in std_logic;
          enable        : in std_logic;
          int_in        : in std_logic;
          int_out       : out std_logic);
end component;

begin
    int_out <= '0' when int_lines_out = std_logic_vector(to_unsigned(0, WIDTH)) else '1';
    int_lines : for idx in WIDTH - 1 downto 0 generate
    begin
        cur_int_line : component int_line
            port map(
                clk => clk,
                reset => reset,
                clear => clear,
                enable => enable(idx),
                int_in => int_lines_in(idx),
                int_out => int_lines_out(idx));
    end generate;

end behavioral;
