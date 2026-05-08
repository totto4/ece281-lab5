----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

type sm_state is (clr_display, load_A, load_B, write_display);

signal current_state, next_state: sm_state;

begin

	-- Next State Logic            
  	next_state <=  sm_state'succ(current_state) when (i_adv = '1' and current_state /= write_display) else
  	               clr_display when (i_adv = '1') else
	               current_state;

-- Output logic
	with current_state select
	o_cycle <= "0001" when clr_display,
	           "0010" when load_A,
	           "0100" when load_B,
	           "1000" when write_display;

	-- State register ------------
	state_register : process(i_adv)
	begin
        if rising_edge(i_adv) then
           if i_reset = '1' then
               current_state <= clr_display;
           else
                current_state <= next_state;
            end if;
        end if;
	end process state_register;
end FSM;
