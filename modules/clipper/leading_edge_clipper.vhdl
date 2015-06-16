---------------------------------------------------------------------
----                                                             ----
---- Company:  University of Bonn                                ----
---- Engineer: Daniel Hahne                                      ----
----                                                             ----
---------------------------------------------------------------------
----                                                             ----
---- Copyright (C) 2015 Daniel Hahne                             ----
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity leading_edge_clipper is
    Port ( input : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           output : out  STD_LOGIC := '0');
end leading_edge_clipper;

architecture Behavioral of leading_edge_clipper is
signal q1	: STD_LOGIC := '0';
signal q2	: STD_LOGIC := '0';

begin

process (input, CLK) is
begin
	if (CLK'event AND CLK = '1') then
		q2 <= q1;
		q1 <= input;
	end if;
end process;

process (CLK, q1, q2) is
begin
	if (CLK'event AND CLK = '1') then
		output <= q1 AND NOT q2;
	end if;
end process;

end Behavioral;

