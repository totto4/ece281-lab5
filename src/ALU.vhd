----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    
    signal w_B : STD_LOGIC_VECTOR (7 downto 0);
    signal w_Sum : STD_LOGIC_VECTOR (7 downto 0);
    signal w_Cout : STD_LOGIC;
    signal w_result : STD_LOGIC_VECTOR (7 downto 0);

    component ripple_adder is
            port (   A : in STD_LOGIC_VECTOR (7 downto 0);
                     B : in STD_LOGIC_VECTOR (7 downto 0);
                     Cin_Ripple : in STD_LOGIC;
                     S_Ripple : out STD_LOGIC_VECTOR (7 downto 0);
                     Cout_Ripple : out STD_LOGIC);
     end component ripple_adder;

begin

    with i_op(0) select
	     w_B <= i_B when '0',
	         not i_B when '1',
	         i_B when others;

    ripple_adder_0: ripple_adder
	port map( 
	  Cin_Ripple   => i_op(0),
	  A => i_A,
	  B => w_B,
	  S_Ripple  => w_Sum,
	  Cout_Ripple  => w_Cout
	  );
	   
	  with i_op select
	  w_result <= w_Sum when "000",
	              w_Sum when "001",
	              (i_A and i_B) when "010",
	              (i_A or i_B) when "011",
	              x"00" when others;

     o_flags(0) <= (not (i_op(0) xor i_A(7) xor i_B(7))) and (i_A(7) xor w_Sum(7)) and (not i_op(1));
     o_flags(1) <= w_Cout and (not i_op(1));
     o_flags(2) <= (w_result(0) nor w_result(1)) and (w_result(2) nor w_result(3)) and (w_result(4) nor w_result(5)) and (w_result(6) nor w_result(7));
     o_flags(3) <= w_result(7);
     o_result <= w_result;
     
     
end Behavioral;
