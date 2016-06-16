-----------------------------------------------------------------------
-- pifWS2812B.vhd    Bugblat pif smart LED flasher
--
-- Initial entry: 05-Jun-16 te
--
-- Copyright (c) 2001 to 2016  te
--
-----------------------------------------------------------------------
-- This example drives the two RGB LEDs with the pseudo-random bits from
-- a 24-bit Linear Feedback Shift Register (LFSR). The result isn't very
-- artistic, a better algorithm should be pretty easy to construct.
--
-- Because the WS2812B LEDs are rather bright, we force the intensity MSB
-- for each color to zero, halving the maximum brightness.
--
-- One possibility for an improved algorith would be this:
--   for each of R,G,B use the LFSR to generate an intensity
--   gradient (i.e. a step size to add to or subtract from the
--   current value). Then limit the maximum and minimum intensities
--   reversing the direction when the max or min is hit.
--
-----------------------------------------------------------------------
library ieee;                 use ieee.std_logic_1164.all;
                              use ieee.numeric_std.all;
library machxo2;              use machxo2.components.all;

entity WS2812B is
  generic ( SEED : std_logic_vector(1 downto 0) := "11" );
  port (
    clk, shiftIn  : in  std_logic;
    load, shift   : in  boolean;
    shiftOut      : out std_logic  );
end WS2812B;

architecture rtl of WS2812B is

  subtype slv24 is std_logic_vector(23 downto 0);

  signal  gbr       : slv24 := (2=>'1', 1=>SEED(1), 0=>SEED(0), others=>'0');
  signal  shiftReg  : slv24 := (others=>'0');

begin
  process (clk) begin
    if rising_edge(clk) then
      gbr(23 downto 1) <= gbr(22 downto 0);
      gbr(0)           <= not( gbr(23) xor gbr(22) xor gbr(21) xor gbr(16) );
      if load then
        shiftReg <= '0' & gbr(3*8-2 downto 2*8) &
                    '0' & gbr(2*8-2 downto 1*8) &
                    '0' & gbr(1*8-2 downto 0*8);
      elsif shift then
        shiftReg <= shiftReg(shiftReg'high-1 downto 0) & shiftIn;
      end if;
    end if;
  end process;

  shiftOut <= shiftReg(shiftReg'high);

end rtl;

-----------------------------------------------------------------------
library ieee;                 use ieee.std_logic_1164.all;
                              use ieee.numeric_std.all;
--                            use ieee.math_real.all;
library machxo2;              use machxo2.components.all;

entity WS2812B_pair is
  port (
    clk       : in  std_logic;
    wsOut     : out std_logic );
end WS2812B_pair;

architecture rtl of WS2812B_pair is
  -----------------------------------------------
  component WS2812B is
    generic ( SEED : std_logic_vector(1 downto 0) := "11" );
    port (
      clk, shiftIn: in  std_logic;
      load, shift : in  boolean;
      shiftOut    : out std_logic  );
  end component WS2812B;
  -----------------------------------------------

  type TWSstate is ( Wstart, Wload0, Wload1, Whi, Wlo, Wturn0, Wturn1 );
  signal  WSstate : TWSstate;

  signal  load, shift : boolean;

  constant  NUM_LEDS  : natural := 2;
  constant  NUM_BITS  : natural := NUM_LEDS * 24;
  signal  shiftCount  : natural range 0 to NUM_BITS := 0;

  constant HI0  : natural := 11;        -- 400ns
  constant LO0  : natural := 23;        -- 850ns
  constant HI1  : natural := 21;        -- 800ns
  constant LO1  : natural := 12;        -- 450ns
  constant PULSE_MAX : natural := LO0;
  signal  pulseCount, hiLen, loLen
                     : natural range 0 to PULSE_MAX;

  signal  shiftOutX, shiftOut : std_logic;

  signal  turnCounter : unsigned(25 downto 0);

  signal  reset       : boolean := true;      -- assume initialiser is honoured

begin
  ---------------------------------------------------------------------
  -- Power-Up Reset for 16 clocks
  -- assumes initialisers are honoured by the synthesiser
  RST_BLK: block
    signal nrst      : boolean := false;
    signal rst_count : integer range 0 to 15 := 0;
  begin
    process (clk) begin
      if rising_edge(clk) then
        if rst_count /= 15 then
          rst_count <= rst_count +1;
        end if;
        nrst  <= rst_count=15;
        reset <= not nrst;
      end if;
    end process;
  end block RST_BLK;

  --------------------------------
  W1: WS2812B generic map (SEED => "01")
    port map (
      clk     => clk,
      shiftIn => '0',
      load    => load,
      shift   => shift,
      shiftOut=> shiftOutX );

  W2: WS2812B generic map (SEED => "10")
    port map (
      clk     => clk,
      shiftIn => shiftOutX,
      load    => load,
      shift   => shift,
      shiftOut=> shiftOut );
  --------------------------------

  process(clk)
    variable vShift : boolean;
  begin
    if rising_edge(clk) then
      vShift := false;
      if reset then
        WSstate <= Wstart;
        wsOut <= '0';
      else
        case WSstate is
          when Wstart =>
            hiLen <= PULSE_MAX;
            WSstate <= Wload0;

          when Wload0 =>
            shiftCount <= 0;
            WSstate <= Wload1;

          when Wload1 =>
            pulseCount <= 0;
            wsOut <= '1';
            WSstate <= Whi;

          when Whi =>
            if shiftOut='0' then
              hiLen <= HI0 -1;
              loLen <= LO0 -1;
            else
              hiLen <= HI1 -1;
              loLen <= LO1 -1;
            end if;

            if (pulseCount >= hiLen) then
              vShift := true;
              shiftCount <= shiftCount+1;
              pulseCount <= 0;
              wsOut <= '0';
              WSstate <= Wlo;
            else
              pulseCount <= pulseCount+1;
            end if;

          when Wlo =>
            if (pulseCount >= loLen) then
              pulseCount <= 0;
              wsOut <= '1';
              if (shiftCount >= NUM_BITS) then
                wsOut <= '1';
                WSstate <= Wturn0;
              else
                WSstate <= Whi;
              end if;
            else
              pulseCount <= pulseCount+1;
            end if;

          when Wturn0 =>
            turnCounter <= (others=>'0');
            wsOut <= '0';
            WSstate <= Wturn1;

          when Wturn1 =>
            turnCounter <= turnCounter+1;
            if turnCounter(turnCounter'high)='1' then
              WSstate <= Wstart;
      end if;

        end case;
      end if;
      shift <= vShift;
    end if;
  end process;

  load   <= (WSstate = Wload0);

end rtl;

-- EOF pifWS2812B.vhd -------------------------------------------------
