library ieee;

use ieee.std_logic_1164.all;

entity int_line_mux is port(
    clk : in std_logic;
    reset : in std_logic;
    ack : in std_logic;
    config : in std_logic_vector(31 downto 0);
    int_lines_in : in std_logic_vector(7 downto 0);
    out_level : out std_logic_vector(2 downto 0);
    int_lines_out : out std_logic_vector(7 downto 0));
end int_line_mux;

architecture behavioral of int_line_mux is

component int_line
    port (clk           : in std_logic;
          reset         : in std_logic;
          ack           : in std_logic;
          trigger_level : in std_logic;
          level_in      : in std_logic_vector (2 downto 0);
          level_out     : out std_logic_vector (2 downto 0);
          int_in        : in std_logic;
          int_out       : out std_logic);
end component;

type level_array is array(0 to 7) of std_logic_vector(2 downto 0);
signal level_outs : level_array;

function find_max_level(cur_levels : level_array) return std_logic_vector is
   variable tmp: level_array := cur_levels;
   variable i,j : integer;
begin
   for lvl in 0 to tmp'right/2 loop -- should be log2(tmp'right)
       for itm in 0 to tmp'right loop
           i := 2**(lvl+1) * itm;
           j := i + 2**lvl;
           next when ((i > tmp'right) or (j > tmp'right));
           if (tmp(j) > tmp(i)) then
               tmp(i) := tmp(j);
           end if;
       end loop;
    end loop;
    return tmp(0);
end find_max_level;

begin
    out_level <= find_max_level(level_outs);
    int_lines : for idx in 0 to 7 generate
        constant level_start_idx : integer := idx * 4;
        constant level_end_idx : integer := level_start_idx + 3;
        constant trigger_level_idx : integer := level_end_idx + 1;
    begin
        cur_int_line : component int_line
            port map(
                clk => clk,
                reset => reset,
                ack => ack,
                trigger_level => config(trigger_level_idx),
                level_in => config(level_end_idx downto level_start_idx),
                level_out => level_outs(idx),
                int_in => int_lines_in(idx),
                int_out => int_lines_out(idx));
    end generate;

end behavioral;
