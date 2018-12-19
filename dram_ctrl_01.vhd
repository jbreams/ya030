----------------------------------------------------------------
-- DRAM controller for T030 SBC v0.1
-- (c) 2016 Tobias Rathje
--
-- FSM based on Lattice RD1014 (Fast Page Mode DRAM Controller)
-- 
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dram_ctrl is port
(
  clk                   : in    std_logic;                      -- Clock
  cs                    : in    std_logic;                      -- Chip select
  reset                 : in    std_logic;                      -- Reset signal
  rw                    : in    std_logic;                      -- Processor Read/Write signal
  siz0, siz1            : in    std_logic;                      -- Data size from CPU
  a                     : in    std_logic_vector(23 downto 0);  -- Processor address lines
  dtack                 : out   std_logic;                      -- Data ack signal to CPU
  ras                   : out   std_logic;                      -- DRAM RAS signal
  cas0,cas1,cas2,cas3   : out   std_logic;                      -- DRAM CAS signals
  we                    : out   std_logic;                      -- DRAM write enable signal
  ma                    : out   std_logic_vector(10 downto 0)   -- DRAM address lines
);
end dram_ctrl;

architecture behavioral of dram_ctrl is

-- Asynchronous versions of outputs to be synchronized to clk in the "sync_ctl" process
signal  rasa                        : std_logic;
signal  cas0a, cas1a, cas2a, cas3a  : std_logic;
signal  dtacka                      : std_logic;
signal  wea, refacka                : std_logic;

-- Other internal signals
signal  refreq          : std_logic;                    -- Refresh Request
signal  tc              : std_logic;                    -- Refresh counter terminal count signal
signal  q               : std_logic_vector(8 downto 0); -- The refresh counter
signal  refack          : std_logic;
signal  ps, ns          : std_logic_vector(3 downto 0);
signal  mux, mxs                : std_logic;                                    -- Mux signal
signal  caswr                   : std_logic_vector(3 downto 0); -- CAS vector for write

--state declarations
constant idle   : std_logic_vector(3 downto 0) := "0000";
constant rw1    : std_logic_vector(3 downto 0) := "0001";
constant rw1x   : std_logic_vector(3 downto 0) := "1010";
constant rw2    : std_logic_vector(3 downto 0) := "0011";
constant rw3    : std_logic_vector(3 downto 0) := "0010";
constant rw3x   : std_logic_vector(3 downto 0) := "1110";
constant cbr1   : std_logic_vector(3 downto 0) := "0111";
constant cbr2   : std_logic_vector(3 downto 0) := "0101";
constant cbr3   : std_logic_vector(3 downto 0) := "0100";
constant cbr3x  : std_logic_vector(3 downto 0) := "1011";
constant cbr4   : std_logic_vector(3 downto 0) := "1000";
constant prechg : std_logic_vector(3 downto 0) := "1001";

begin

-- Address mux
ma      <= a(12 downto 2) when mxs = '1' else
           a(23 downto 13);

-- Transfer LUT
caswr <= "0111" when siz1 = '0' and siz0 = '1' and a(1) = '0' and a(0) = '0' else
         "1011" when siz1 = '0' and siz0 = '1' and a(1) = '0' and a(0) = '1' else
         "1101" when siz1 = '0' and siz0 = '1' and a(1) = '1' and a(0) = '0' else
         "1110" when siz1 = '0' and siz0 = '1' and a(1) = '1' and a(0) = '1' else
         "0011" when siz1 = '1' and siz0 = '0' and a(1) = '0' and a(0) = '0' else
         "1001" when siz1 = '1' and siz0 = '0' and a(1) = '0' and a(0) = '1' else
         "1100" when siz1 = '1' and siz0 = '0' and a(1) = '1' and a(0) = '0' else
         "1110" when siz1 = '1' and siz0 = '0' and a(1) = '1' and a(0) = '1' else
         "0001" when siz1 = '1' and siz0 = '1' and a(1) = '0' and a(0) = '0' else
         "1000" when siz1 = '1' and siz0 = '1' and a(1) = '0' and a(0) = '1' else
         "1100" when siz1 = '1' and siz0 = '1' and a(1) = '1' and a(0) = '0' else
         "1110" when siz1 = '1' and siz0 = '1' and a(1) = '1' and a(0) = '1' else
         "0000" when siz1 = '0' and siz0 = '0' and a(1) = '0' and a(0) = '0' else
         "1000" when siz1 = '0' and siz0 = '0' and a(1) = '0' and a(0) = '1' else
         "1100" when siz1 = '0' and siz0 = '0' and a(1) = '1' and a(0) = '0' else
         "1110" when siz1 = '0' and siz0 = '0' and a(1) = '1' and a(0) = '1' else
         "1111";

---------------------------------------
------ Asynchronous process -----------
---------------------------------------
       
as_cont: process (cs, refreq, ps, rw, caswr)
begin

case ps is
    when idle =>
        rasa    <= '1';
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';  
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= rw;
        if (refreq = '1') then 
            ns      <= cbr1;         -- do a refresh cycle
            wea     <= '1';
            dtacka  <= '1';
            rasa    <= '1';
            cas0a   <= '1';
            cas1a   <= '1';
            cas2a   <= '1';
            cas3a   <= '1';
            mux     <= '0';
        elsif (cs = '0') then 
            ns      <= rw1;          -- do a normal read/write cycle
            wea     <= rw;
            dtacka  <= '1';
            rasa    <= '1';
            cas0a   <= '1';
            cas1a   <= '1';
            cas2a   <= '1';
            cas3a   <= '1';
            mux     <= '1';
        else 
            ns      <= idle;
            wea     <= '1';
            dtacka  <= '1';
            rasa    <= '1';
            cas0a   <= '1';
            cas1a   <= '1';
            cas2a   <= '1';
            cas3a   <= '1';
            mux   <= '0';
        end if;

    when rw1 =>                     -- DRAM access start
        rasa    <= '0';                         -- RAS active
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';  
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '1';
        wea     <= rw;
        ns      <= rw1x;

    when rw1x =>                 
        rasa    <= '0';                         -- RAS active
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';  
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= rw;
        ns      <= rw2;  
          
    when rw2 =>                         -- dsackx sampled at start of this state
        rasa    <= '0';
        if (rw = '1') then
            cas0a   <= '0';                             -- CAS active
            cas1a   <= '0';
            cas2a   <= '0';
            cas3a   <= '0';
        else
            cas0a   <= caswr(0);
            cas1a   <= caswr(1);
            cas2a   <= caswr(2);
            cas3a   <= caswr(3);
        end if;
        dtacka  <= '0';
        mux     <= '0';
        refacka <= '0';
        wea     <= rw;
        ns      <= rw3;
 
    when rw3 =>                  -- Read data sampled at start of this state  
        rasa    <= '1';
        if (rw = '1') then
            cas0a   <= '0';          -- CAS active
            cas1a   <= '0';
            cas2a   <= '0';
            cas3a   <= '0';
        else
            cas0a   <= caswr(0);
            cas1a   <= caswr(1);
            cas2a   <= caswr(2);
            cas3a   <= caswr(3);
        end if;
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= '1';
        ns      <= prechg;            
         
    when cbr1 =>                 -- CBR mode start
        rasa    <= '1';
        cas0a   <= '0';             -- start with CAS
        cas1a   <= '0';
        cas2a   <= '0';
        cas3a   <= '0';                  
        dtacka  <= '1';
        refacka <= '1';           --refresh request register clear
        wea     <= '1';           --refresh mode
        mux     <= '0';
        ns      <= cbr2;

    when cbr2 =>
        rasa    <= '0';                         -- then RAS
        cas0a   <= '0';
        cas1a   <= '0';
        cas2a   <= '0';
        cas3a   <= '0';                  
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= cbr3;

    when cbr3 =>         
        rasa    <= '0';                         
        cas0a   <= '1';                     -- deassert CAS
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';          
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= cbr4;

    when cbr4 =>
        rasa    <= '1';                         -- deassert RAS
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';          
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= prechg;

    when prechg =>
        rasa    <= '1';
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';  
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= idle;
    when others =>
        rasa    <= '1';
        cas0a   <= '1';
        cas1a   <= '1';
        cas2a   <= '1';
        cas3a   <= '1';  
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= rw;
        ns      <= idle;
end case;
end process;

---------------------------------------------
-------- Synchronous Process  ---------------
---------------------------------------------
sync_ctl: process (clk, reset)
begin
    if (reset = '0') then
        ps      <= idle;
        ras             <= '1';
        cas0    <= '1';
        cas1    <= '1';
        cas2    <= '1';
        cas3    <= '1';  
        dtack   <= '1';
        we      <= '1';
        refack  <= '0';
    elsif (clk'event and clk = '0') then      -- state machine clocked on falling edge
        ps      <= ns;                        -- update the state machine state
        ras     <= rasa;                      -- and assert the synchronous outputs
        cas0    <= cas0a;
        cas1    <= cas1a;
        cas2    <= cas2a;
        cas3    <= cas3a;
        dtack   <= dtacka;
        we      <= wea;
        refack  <= refacka;
        mxs     <= mux;
    end if;
end process;

---------------------------------------
----    refresh counter 
----    9bits 15.6us interval
---------------------------------------

rfcnt: process(clk, refack, reset)
begin
    if (reset = '0') then
        q <= "000000000";
    elsif (clk'event and clk = '0') then
        if(refack = '1') then
            q <= "000000000";
        else
            q <= q + 1;
        end if;
    end if;
end process;

-- 186hex = 110000110 binary = 390 decimal
-- assuming 25 MHz clock (40ns clock period)
-- 40ns (tCYC) x 390 = 15.6us is the refresh request rate.

tc <=   '1' when q = "110000110" else
        '0';

rreq: process (clk, tc, refack, reset)
begin
    if (reset = '0') then
        refreq <= '0';
    elsif (clk'event and clk = '0') then
        if refack = '1' then
            refreq <= '0';
        elsif tc = '1' then                    -- assert refreq when the terminal count (tc) is reached
            refreq <= '1';
        end if;
    end if;
end process;

end behavioral;
