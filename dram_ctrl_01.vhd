----------------------------------------------------------------
-- DRAM and ROM controller for a 68040 CPU, based on the DRAM controller
-- written for the T030 SBC here https://hackaday.io/project/9439-t030
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity dram_ctrl is port
(
  clk                   : in    std_logic;                      -- Clock
  reset                 : in    std_logic;                      -- Reset signal
  rw                    : in    std_logic;                      -- Processor Read/Write signal
  siz0, siz1            : in    std_logic;                      -- Data size from CPU
  pa                    : in    std_logic_vector(28 downto 0);  -- Processor address lines
  rom_oe                : out   std_logic;                      -- Output Enable for ROM SIMM
  edo_inhibit           : out   std_logic;                      -- Inhibits line reads/writes
  dtack                 : out   std_logic;                      -- Data ack signal to CPU
  ras                   : out   std_logic_vector(3 downto 0);   -- DRAM RAS signals (banks 1-4)
  cas                   : out   std_logic_vector(3 downto 0);   -- DRAM CAS signals (columns 1-4)
  we                    : out   std_logic;                      -- DRAM write enable signal
  ma                    : out   std_logic_vector(11 downto 0)   -- DRAM address lines
);
end dram_ctrl;

architecture behavioral of dram_ctrl is

-- Asynchronous versions of outputs to be synchronized to clk in the "sync_ctl" process
signal  rasa                        : std_logic_vector(3 downto 0);
signal  casa                        : std_logic_vector(3 downto 0);
signal  dtacka                      : std_logic;
signal  wea, refacka                : std_logic;
signal  rom_oea                     : std_logic;
signal  edo_inhibita                : std_logic;

-- Other internal signals
signal  a               : std_logic_vector(28 downto 0);  -- Latched address
signal  ram_base        : std_logic_vector(28 downto 0);
signal  edocounter      : unsigned(1 downto 0);   -- EDO counter
signal  edoenabled      : std_logic;                      -- Whether EDO is inabled
signal  refreq          : std_logic;                      -- Refresh Request
signal  refcounter      : unsigned(7 downto 0);   -- The refresh counter
signal  refack          : std_logic;                      -- Refresh acknowledged
signal  ps, ns          : std_logic_vector(3 downto 0);
signal  mux, mxs        : std_logic;                      -- Mux signal
signal  caswr           : std_logic_vector(3 downto 0);   -- CAS vector for write
signal  rasmux          : std_logic_vector(3 downto 0);   -- RAS bank selector
signal  rom_cs          : std_logic;

--state declarations
constant idle       : std_logic_vector(3 downto 0) := "0000";
constant rw1        : std_logic_vector(3 downto 0) := "0001";
constant rw1x       : std_logic_vector(3 downto 0) := "0010";
constant rw2        : std_logic_vector(3 downto 0) := "0011";
constant rw3        : std_logic_vector(3 downto 0) := "0100";
constant rw3x       : std_logic_vector(3 downto 0) := "0101";
constant cbr1       : std_logic_vector(3 downto 0) := "0110";
constant cbr2       : std_logic_vector(3 downto 0) := "0111";
constant cbr3       : std_logic_vector(3 downto 0) := "1000";
constant cbr3x      : std_logic_vector(3 downto 0) := "1001";
constant cbr4       : std_logic_vector(3 downto 0) := "1010";
constant prechg     : std_logic_vector(3 downto 0) := "1011";
constant rom_wait1  : std_logic_vector(3 downto 0) := "1100";
constant rom_wait2  : std_logic_vector(3 downto 0) := "1101";

constant allon      : std_logic_vector(3 downto 0) := "1111";
constant alloff     : std_logic_vector(3 downto 0) := "0000";

-- Maximum addresses for different banks of memory
constant rom      : unsigned := x"800000";
constant bank1    : unsigned := x"8800000";
constant bank2    : unsigned := x"10800000";
constant bank3    : unsigned := x"18800000";
constant bank4    : unsigned := x"20800000";

-- 186hex = 110000110 binary = 390 decimal
-- assuming 25 MHz clock (40ns clock period)
-- 40ns (tCYC) x 390 = 15.6us is the refresh request rate.
constant refmaxcount : unsigned := x"186";
begin

-- Address mux
ram_base <= std_logic_vector(unsigned(a) - rom);
ma      <= ram_base(13 downto 2) when mxs = '1' else
           ram_base(25 downto 14);

-- RAM bank selection
rasmux  <= "0001" when unsigned(a) > rom and unsigned(a) <= bank1 else
           "0010" when unsigned(a) > bank1 and unsigned(a) <= bank2 else
           "0100" when unsigned(a) > bank2 and unsigned(a) <= bank3 else
           "1000" when unsigned(a) > bank3 and unsigned(a) <= bank4 else
           "0000";

-- ROM will be enabled when rom >= a > 0
rom_cs <= '1' when unsigned(a) <= rom else '0';

-- Decode size information
caswr <= "0111" when siz0 = '1' and siz1 = '0' and a(0) = '0' and a(1) = '0' else
         "1011" when siz0 = '1' and siz1 = '0' and a(0) = '0' and a(1) = '1' else
         "1101" when siz0 = '1' and siz1 = '0' and a(0) = '1' and a(1) = '0' else
         "1110" when siz0 = '1' and siz1 = '0' and a(0) = '1' and a(1) = '1' else
         "0011" when siz0 = '0' and siz1 = '1' and a(0) = '0' and a(1) = '0' else
         "1100" when siz0 = '0' and siz1 = '1' and a(0) = '0' and a(1) = '1' else
         "0000";

edoenabled <= '1' when siz0 = '0' and siz1 = '0' else '0';

---------------------------------------
------ Asynchronous process -----------
---------------------------------------
       
as_cont: process (refreq, ps, caswr, rasmux, rom_cs)
begin

case ps is
    when idle =>
        rasa         <= allon;
        casa         <= allon;
        dtacka       <= '1';
        refacka      <= '0';
        mux          <= '0';
        wea          <= '1';
        rom_oea      <= '1';
        edo_inhibita <= '0';

        if (refreq = '1') then 
            ns      <= cbr1;         -- do a refresh cycle
        elsif (rom_cs = '1') then    -- wait two clock cycles for the ROM to enable
            ns      <= rom_wait1;
            rom_oea <= '0';
            -- We don't support EDO for reads from ROM
            if (edoenabled = '1') then
                edo_inhibita <= '1';
            end if;
        elsif (rasmux = alloff) then
            ns      <= idle;         -- idle the DRAM
        else
            ns      <= rw1;          -- do a normal read/write cycle
            wea     <= rw;
            mux     <= '1';
            edocounter <= to_unsigned(0, 2);
			   -- If EDO is not enabled or if this is the first read in the burst transfer,
            -- latch the address from the processor
            if (edoenabled = '0' or edocounter = 0) then
                a       <= pa;
            end if;
        end if;

    -- ROM is super slow and may take up to three clock cycles for the data to be
    -- put on the data lines, so we have two states that are just here to insert
    -- wait states.
    when rom_wait1 =>
        ns      <= rom_wait2;
        rom_oea <= '0';
        wea     <= '1';
        dtacka  <= '1';
        mux     <= '0';

    when rom_wait2 =>
        ns      <= idle;
        rom_oea <= '0';
        wea     <= '1';
        dtacka  <= '0';
        mux     <= '0';

    when rw1 =>                     -- DRAM access start
        rasa    <= rasmux;
        casa    <= allon;
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '1';
        wea     <= rw;
        ns      <= rw1x;

    when rw1x =>                    -- RAS active
        rasa    <= rasmux;
        casa    <= allon;
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= rw;
        ns      <= rw2;  
          
    when rw2 =>                     -- dsackx sampled at start of this state
        rasa    <= rasmux;
        casa    <= caswr;           -- CAS active
        dtacka  <= '0';
        mux     <= '0';
        refacka <= '0';
        wea     <= rw;
        ns      <= rw3;
 
    when rw3 =>                  -- Read data sampled at start of this state
        rasa    <= allon;
        casa    <= caswr;
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        wea     <= '1';

        -- If EDO is not enabled or we've already read a full line (4 bytes) then the next
        -- state is precharge.
        if (edoenabled = '0' or edocounter = 3) then
            ns         <= prechg;
            edocounter <= to_unsigned(0, 2);
        else
        -- Otherwise increment the EDO counter and address by one and go back to rw2. This
        -- will let us go to the next column with only one clock cycle.
            edocounter <= edocounter + 1;
            ns         <= rw2;
            a          <= a + 4;
        end if;
         
    when cbr1 =>                 -- CBR mode start
        rasa    <= allon;
        casa    <= alloff;       -- start with CAS
        dtacka  <= '1';
        refacka <= '1';           --refresh request register clear
        wea     <= '1';           --refresh mode
        mux     <= '0';
        ns      <= cbr2;

    when cbr2 =>
        rasa    <= alloff;       -- then RAS
        casa    <= alloff;
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= cbr3;

    when cbr3 =>
        rasa    <= alloff;
        casa    <= allon;        -- deassert CAS
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= cbr4;

    when cbr4 =>
        rasa    <= allon;        -- deassert RAS
        casa    <= allon;
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= prechg;

    when prechg =>
        rasa    <= allon;
        casa    <= allon;
        dtacka  <= '1';
        refacka <= '0';
        wea     <= '1';
        mux     <= '0';
        ns      <= idle;
    when others =>
        rasa    <= allon;
        casa    <= allon;
        dtacka  <= '1';
        refacka <= '0';
        mux     <= '0';
        rom_oea <= '1';
        edo_inhibita <= '0';
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
        ps         <= idle;
        ras        <= allon;
        cas        <= allon;
        dtack      <= '1';
        we         <= '1';
        refack     <= '0';
        rom_oe     <= '1';
        edo_inhibit <= '0';
    elsif (clk'event and clk = '0') then   -- state machine clocked on falling edge

        ps          <= ns;                -- update the state machine state
        ras         <= rasa;
        cas         <= casa;              -- and assert the synchronous outputs
        dtack       <= dtacka;
        we          <= wea;
        refack      <= refacka;
        mxs         <= mux;
        rom_oe      <= rom_oea;
        edo_inhibit <= edo_inhibita;
    end if;
end process;

---------------------------------------
----    refresh counter 
----    9bits 15.6us interval
---------------------------------------

rfcnt: process(clk, refack, reset)
begin
    if (reset = '0') then
        refcounter <= to_unsigned(0, 8);
    elsif (clk'event and clk = '0') then
        if(refack = '1') then
            refcounter <= to_unsigned(0, 8);
        else
            refcounter <= refcounter + 1;
        end if;
    end if;
end process;

rreq: process (clk, refcounter, refack, reset)
begin
    if (reset = '0') then
        refreq <= '0';
    elsif (clk'event and clk = '0') then
        if refack = '1' then
            refreq <= '0';
        elsif unsigned(refcounter) = refmaxcount then
            refreq <= '1';
        end if;
    end if;
end process;

end behavioral;
