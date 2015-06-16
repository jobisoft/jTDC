---------------------------------------------------------------------
----                                                             ----
---- Company:  University of Bonn                                ----
---- Engineer: John Bieling                                      ----
----                                                             ----
---------------------------------------------------------------------
----                                                             ----
---- Copyright (C) 2015 John Bieling                             ----
----                                                             ----
---- This source file may be used and distributed without        ----
---- restriction provided that this copyright statement is not   ----
---- removed from the file and that any derivative work contains ----
---- the original copyright notice and the associated disclaimer.----
----                                                             ----
----     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ----
---- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ----
---- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ----
---- FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ----
---- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ----
---- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ----
---- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ----
---- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ----
---- BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ----
---- LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ----
---- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ----
---- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ----
---- POSSIBILITY OF SUCH DAMAGE.                                 ----
----                                                             ----
---------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity leading_edge_extractor is
    Port ( sig : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           unclipped_extend : in STD_LOGIC_VECTOR (4 downto 0);
           unclipped_sig : out  STD_LOGIC;
           clipped_sig : out  STD_LOGIC);
end leading_edge_extractor;

architecture Behavioral of leading_edge_extractor is
signal q_sync : STD_LOGIC;

signal q0     : STD_LOGIC;
signal q1     : STD_LOGIC;
signal q2     : STD_LOGIC;

signal q0_ext : STD_LOGIC;
signal q1_ext : STD_LOGIC;
signal q2_ext : STD_LOGIC;

begin

signal_extender : SRL16
   generic map (
      INIT => X"0000")
   port map (
      Q => q1_ext,                -- SRL data output
      A0 => unclipped_extend(1),  -- Select[0] input
      A1 => unclipped_extend(2),  -- Select[1] input
      A2 => unclipped_extend(3),  -- Select[2] input
      A3 => unclipped_extend(4),  -- Select[3] input
      CLK => CLK,                 -- Clock input
      D => q0_ext                 -- SRL data input
   );

signal_extender_double : SRL16
   generic map (
      INIT => X"0000")
   port map (
      Q => q0_ext,                -- SRL data output
      A0 => unclipped_extend(1),  -- Select[0] input
      A1 => unclipped_extend(2),  -- Select[1] input
      A2 => unclipped_extend(3),  -- Select[2] input
      A3 => unclipped_extend(4),  -- Select[3] input
      CLK => CLK,                 -- Clock input
      D => q_sync                 -- SRL data input
   );

process (CLK) is
begin
	if (CLK'event AND CLK = '1') then
	    q_sync <= sig;
      
	    q0 <= q_sync;
	    q1 <= q0;
	    q2 <= q1;
	    q2_ext <= q1_ext;
      
	    clipped_sig <= q1 AND NOT q2;
      
	    if (unclipped_extend(0) = '0') then
	        unclipped_sig <= q1 OR q1_ext;
	    else
	        unclipped_sig <= q1 OR q2_ext;
	    end if;
	end if;
end process;

end Behavioral;

