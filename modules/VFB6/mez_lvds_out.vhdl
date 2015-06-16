---------------------------------------------------------------------
----                                                             ----
---- Engineer: Ph. Hoffmeister                                   ----
---- Company:  ELB-Elektroniklaboratorien Bonn UG                ----
----           (haftungsbeschränkt)                              ---- 
----                                                             ----
---------------------------------------------------------------------
----                                                             ----
---- Copyright (C) 2015 ELB                                      ----
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

entity mez_lvds_out is
    Port ( MEZ : inout  STD_LOGIC_VECTOR (73 downto 0);
           data : in  STD_LOGIC_VECTOR (31 downto 0));
end mez_lvds_out;

architecture Behavioral of mez_lvds_out is
   attribute OUT_TERM : string;
   attribute OUT_TERM of MEZ: signal is "UNTUNED_SPLIT_50";
begin

MEZ (1) <= not data (0);
MEZ (0) <= not data (16);
MEZ (3) <= not data (1);
MEZ (2) <= not data (17);
MEZ (5) <= not data (2);
MEZ (4) <= not data (18);
MEZ (7) <= not data (3);
MEZ (6) <= not data (19);
MEZ (9) <= not data (4);
MEZ (8) <= not data (20);
MEZ (11) <= not data (5);
MEZ (10) <= not data (21);
MEZ (13) <= not data (6);
MEZ (12) <= not data (22);
MEZ (15) <= not data (7);
MEZ (14) <= not data (23);

MEZ (41) <= not data (8);
MEZ (40) <= not data (24);
MEZ (43) <= not data (9);
MEZ (42) <= not data (25);
MEZ (45) <= not data (10);
MEZ (44) <= not data (26);
MEZ (47) <= not data (11);
MEZ (46) <= not data (27);
MEZ (49) <= not data (12);
MEZ (48) <= not data (28);
MEZ (51) <= not data (13);
MEZ (50) <= not data (29);
MEZ (53) <= not data (14);
MEZ (52) <= not data (30);
MEZ (55) <= not data (15);
MEZ (54) <= not data (31);

-- MEZ (0) <= data (0);
-- MEZ (1) <= data (16);
-- MEZ (2) <= data (1);
-- MEZ (3) <= data (17);
-- MEZ (4) <= data (2);
-- MEZ (5) <= data (18);
-- MEZ (6) <= data (3);
-- MEZ (7) <= data (19);
-- MEZ (8) <= data (4);
-- MEZ (9) <= data (20);
-- MEZ (10) <= data (5);
-- MEZ (11) <= data (21);
-- MEZ (12) <= data (6);
-- MEZ (13) <= data (22);
-- MEZ (14) <= data (7);
-- MEZ (15) <= data (23);
-- 
-- MEZ (40) <= data (8);
-- MEZ (41) <= data (24);
-- MEZ (42) <= data (9);
-- MEZ (43) <= data (25);
-- MEZ (44) <= data (10);
-- MEZ (45) <= data (26);
-- MEZ (46) <= data (11);
-- MEZ (47) <= data (27);
-- MEZ (48) <= data (12);
-- MEZ (49) <= data (28);
-- MEZ (50) <= data (13);
-- MEZ (51) <= data (29);
-- MEZ (52) <= data (14);
-- MEZ (53) <= data (30);
-- MEZ (54) <= data (15);
-- MEZ (55) <= data (31);

MEZ (73 downto 56) <= (others => '0');
MEZ (39 downto 16) <= (others => '0');

end Behavioral;

