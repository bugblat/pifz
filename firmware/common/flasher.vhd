-----------------------------------------------------------------------
-- flasher.vhd, PIF_Z version with WS2812B LEDs
--
-- Initial entry: 21-Apr-11 te
-- Updated      : 10-Jun-16 te
--
-- VHDL hierarchy is
--      flasher         top level
--      piffla.vhd        does the work!
--      pifWS2812B.vhd    drives the WS2812B LEDs
--
--
-----------------------------------------------------------------------
--
-- Copyright (c) 2001 to 2013  te
--
-----------------------------------------------------------------------
library IEEE;       use IEEE.std_logic_1164.all;
library machxo2;    use machxo2.components.all;

--=====================================================================
entity flasher is
   port ( GSRn      : in  std_logic;
          LEDR,
          LEDG,
          XLED      : out std_logic   );
end flasher;

--=====================================================================
architecture rtl of flasher is
  -----------------------------------------------
  component pif_flasher is port ( red, green, xclk : out std_logic );
  end component pif_flasher;
  -----------------------------------------------
  component WS2812B_pair is port ( clk:in  std_logic; wsOut:out std_logic );
  end component WS2812B_pair;
  -----------------------------------------------

  signal red_flash,
         green_flash,
         xclk,
         wsOut  : std_logic;

  signal GSRnX        : std_logic;
  attribute pullmode  : string;
  attribute pullmode of GSRnX: signal is "UP";  -- else floats

begin
  -- global reset
  IBgsr   : IB  port map ( I=>GSRn, O=>GSRnX );
  GSR_GSR : GSR port map ( GSR=>GSRnX );

  -----------------------------------------------
  -- LED flasher
  F: pif_flasher port map ( red   => red_flash,
                            green => green_flash,
                            xclk  => xclk           );

  -- WS2812B flasher
  W: WS2812B_pair port map ( clk=>xclk, wsOut=>wsOut );

  -----------------------------------------------
  -- drive the LEDs
  REDL: OB port map ( I=>red_flash  , O => LEDR  );
  GRNL: OB port map ( I=>green_flash, O => LEDG  );
  RGB : OB port map ( I=>wsOut,       O => XLED  );

end rtl;
-- EOF ----------------------------------------------------------------
