library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
generic (WIDTH: integer);
port (
    clk : in std_logic;
    reset : in std_logic;
    value : in unsigned(WIDTH - 1 downto 0);
    ack : in std_logic;
    int : out std_logic
);
end timer;

architecture behavioral of timer is
begin

process(clk, reset, value, ack) is
    variable counter: unsigned(WIDTH - 1 downto 0) := to_unsigned(0, WIDTH);
    variable needs_reset : boolean := true;
begin
    if (reset = '1') then
        counter := to_unsigned(0, WIDTH);
        int <= '0';
        needs_reset := false;
    elsif (clk'event and clk = '0') then
        if (ack = '1' and needs_reset) then
            counter := to_unsigned(0, WIDTH);
            int <= '0';
            needs_reset := false;
        elsif (value /= 0 and not needs_reset) then
            counter := counter + 1;
            if (counter = value) then
                int <= '1';
                needs_reset := true;
            end if;
        end if;
    end if;
end process;

end behavioral;
