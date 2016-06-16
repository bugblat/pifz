-- testbench for pifWS2812B xo2 design
-- ============================================================
library ieee;     use ieee.std_logic_1164.all;
                  use ieee.numeric_std.all;
                  use ieee.std_logic_textio.all;
                  use std.textio.all;

library work;     use work.defs.all;

entity test is
end test;

---------------------------------------------------------------
architecture test_arch of test is
  -----------------------------------------------
  component WS2812B_pair is port ( clk:in  std_logic; wsOut:out std_logic );
  end component WS2812B_pair;
  -----------------------------------------------

  signal  clk   : std_logic := '0';
  signal  wsOut : std_logic;

begin
  --------------------------------
  W: WS2812B_pair port map ( clk=>clk, wsOut=>wsOut );
  --------------------------------

  process
    constant PERIOD: time := 37 ns;   -- approx 1000/26.6 ns
  begin
    clk <= '0'; wait for PERIOD/2;
    clk <= '1'; wait for PERIOD/2;
    -- if TestFinished then wait; end if;
  end process;

  STIM: process
    procedure waitFor ( n : natural ) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);   -- wait for n clocks
      end loop;
    end;

  begin
    waitFor(1000);
  end process STIM;


end test_arch;

-- EOF --------------------------------------------------------
