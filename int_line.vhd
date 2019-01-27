library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_line is port (
    clk : in std_logic; -- Clock;
    reset : in std_logic; -- Reset signal from parent controller;
    ack : in std_logic; -- acknowledge from parent controller
    trigger_level : in std_logic;
    level_in : in std_logic_vector(2 downto 0); -- Interrupt level for next interrupt on this line
    level_out : out std_logic_vector(2 downto 0); -- Interrupt level out to CPU
    int_in : in std_logic; -- Interrupt line from peripheral
    int_out : out std_logic -- Interrupt line out to controller
);
end int_line;

architecture behavioral of int_line is
begin

ctrl: process (clk, reset, ack, level_in, int_in, trigger_level)
    variable triggered : std_logic := '0';
    variable trigger_level_latched : std_logic := '0';
    variable cur_level : std_logic_vector(2 downto 0) := "000";
begin
    if (reset = '1') then
        cur_level := level_in;
        level_out <= "000";
        int_out <= '0';
        triggered := '0';
        trigger_level_latched := trigger_level;
    elsif (clk'event and clk = '0') then
        if (ack = '1' and triggered = '1') then
            triggered := '0';
            level_out <= "000";
            int_out <= '0';
        elsif (triggered = '1' and cur_level /= "000") then
            level_out <= cur_level;
            int_out <= '1';
        end if;
    elsif (int_in = trigger_level_latched) then
        triggered := '1';
    end if;
end process;

end behavioral;
