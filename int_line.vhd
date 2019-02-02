library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_line is port (
    clk : in std_logic; -- Clock;
    reset : in std_logic; -- Reset signal from parent controller
    clear : in std_logic; -- Clear signal from parent controller
    enable : in std_logic; -- Enable signal from parent controller
    int_in : in std_logic; -- Interrupt line from peripheral
    int_out : out std_logic -- Interrupt line out to controller
);
end int_line;

architecture behavioral of int_line is
begin

ctrl: process (clk, reset, clear, int_in)
    variable triggered : std_logic := '0';
begin
    if (reset = '1') then
        int_out <= '0';
        triggered := '0';
    elsif (clk'event and clk = '0') then
        if ((clear = '1' and triggered = '1') or enable = '0') then
            triggered := '0';
            int_out <= '0';
        elsif (triggered = '1' and enable = '1') then
            int_out <= '1';
        end if;
    elsif (int_in = '1') then
        triggered := '1';
    end if;
end process;

end behavioral;
