--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset fsm
        btnL    :   in std_logic; -- reset clk
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    component button_debounce is
        Port(	clk: in  STD_LOGIC;
                reset : in  STD_LOGIC;
                button: in STD_LOGIC;
                action: out STD_LOGIC);
    end component button_debounce;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
               i_reset		: in  STD_LOGIC; -- asynchronous
               i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
        );
    end component TDM4;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component twos_comp;

    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    signal w_cycle : STD_LOGIC_VECTOR (3 downto 0);
    signal w_TDM4_clk : STD_LOGIC;
    signal w_adv : STD_LOGIC;
    signal w_reset_fsm: std_logic;
    signal w_reset_clk: std_logic;
    signal w_reset: std_logic;
    signal w_A : STD_LOGIC_VECTOR (7 downto 0);
    signal w_B : STD_LOGIC_VECTOR (7 downto 0);
    signal w_result : STD_LOGIC_VECTOR (7 downto 0);
    signal w_flags : STD_LOGIC_VECTOR (3 downto 0);
    signal w_bin : STD_LOGIC_VECTOR (7 downto 0);
    signal w_op : STD_LOGIC_VECTOR (2 downto 0);
    signal s_D3 : STD_LOGIC;
    signal w_D3, w_D2, w_D1, w_D0 : std_logic_vector (3 downto 0);
    signal w_data : STD_LOGIC_VECTOR (3 downto 0);
    signal w_seg : std_logic_vector(6 downto 0);
    signal w_an :  std_logic_vector(3 downto 0);
    
    
begin
	-- PORT MAPS ----------------------------------------
	clk_divider_0: clock_divider
	   generic map ( k_DIV => 500000/2 )
	   port map ( i_clk => clk,
	              i_reset => w_reset_clk,
	              o_clk => w_TDM4_clk);
	
	button_debounce_0: button_debounce
        port map (  clk => clk,
                    reset => w_reset_clk,
                    button => btnC,
                    action => w_adv);
                    
    button_debounce_1: button_debounce
        port map (  clk => clk,
                    reset => w_reset_clk,
                    button => btnU,
                    action => w_reset_fsm);
                    
    button_debounce_2: button_debounce
        port map (  clk => clk,
                    reset => w_reset_clk,
                    button => btnL,
                    action => w_reset_clk);
                    
    controller_fsm_0: controller_fsm
        port map (  i_reset => w_reset_fsm,
                    i_adv => w_adv,
                    o_cycle => w_cycle);
                    
    ALU_0: ALU
        port map( i_A => w_A,
                  i_B => w_B,
                  i_op => sw(2 downto 0),
                  o_result => w_result,
                  o_flags => w_flags);
                  
    twos_comp_0: twos_comp
        port map( o_sign => s_D3,
                  o_hund => w_D2,
                  o_tens => w_D1,
                  o_ones => w_D0,
                  i_bin => w_bin);
    
    TDM4_0: TDM4
        port map( i_D3 => w_D3,
                  i_D2 => w_D2,
                  i_D1 => w_D1,
                  i_D0 => w_D0,
                  i_clk => w_TDM4_clk,
                  i_reset => w_reset,
                  o_data => w_data,
                  o_sel => w_an);
                  
    sevenseg_decoder_inst : sevenseg_decoder 
        port map ( i_Hex => w_data,
    	           o_seg_n => w_seg);
                  
    cycle_process_A: process(w_cycle(1))
        begin
            if (rising_edge(w_cycle(1))) then
                w_A <= sw(7 downto 0);
            end if;
    end process;
    
    cycle_process_B: process(w_cycle(2))
        begin
            if (rising_edge(w_cycle(2))) then
                w_B <= sw(7 downto 0);
            end if;
    end process;
	
	-- CONCURRENT STATEMENTS ----------------------------
	with w_cycle select
	   w_bin <= w_A when "0010",
	            w_B when "0100",
	            w_result when "1000",
	            w_bin when others;
	            
	with w_cycle select
	   an <= x"F" when "0001",
	         w_an when others;
	
	with s_D3 select            
	   w_D3 <= x"F" when '1',
	           x"E" when others;
	            
	          
	seg <= w_seg;            
    led(3 downto 0) <= w_cycle;
    led(15 downto 12) <= w_flags;
    w_reset <= w_reset_fsm or w_reset_clk;
    led(11 downto 4) <= "00000000";
	
	
end top_basys3_arch;
