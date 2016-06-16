-----------------------------------------------------------------------
-- pifcfg.vhd, PIF_Z version
--
-- Initial entry: 01-Mar-15 te
-- non-common definitions to personalise the pif implementations
--
-----------------------------------------------------------------------
library ieee;                   use ieee.std_logic_1164.all;

package pifcfg is

  -- PIF_Z ID = 44h = 'D'
  constant PIF_ID      : std_logic_vector(7 downto 0) := x"44"; -- 'D'
  constant XO2_DENSITY : string                       := "2000L";

end package pifcfg;

-----------------------------------------------------------------------
package body pifcfg is
end package body pifcfg;

-----------------------------------------------------------------------
-- EOF pifcfg.vhd
