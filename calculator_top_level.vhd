----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Avery Widen
-- 
-- Create Date: 06/02/2022 04:37:08 PM
-- Design Name: 
-- Module Name: calculator_top_level - Behavioral
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
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;


entity calculator_top_level is
  Port (
  	clk_ext_port     	  : in  std_logic;						--ext 100 MHz clock
	
	RsRx_ext_port		  : in std_logic;				
	RsTx_ext_port      	  : out std_logic);  
end calculator_top_level;

architecture Behavioral of calculator_top_level is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--System Clock Generation:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

component system_clock_generation is
    Port (
        --External Clock:
            input_clk_port		: in std_logic;
        --System Clock:
            system_clk_port		: out std_logic);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Sci Reciever
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component SCI_Rx is
PORT ( 	clk			: 	in 	STD_LOGIC;
		reset		:	in 	STD_LOGIC;
        New_data	:	in	STD_LOGIC;
        Char_out	: 	out	STD_LOGIC_VECTOR(7 downto 0);
        Rx			:	out STD_LOGIC);
end component;


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Sci Transmitter
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component SCI_Tx is
PORT ( 	clk			: 	in 	STD_LOGIC;
		reset		: 	in	STD_LOGIC;
		Char_in		: 	in 	STD_LOGIC_VECTOR(7 downto 0);
        New_data	:	in	STD_LOGIC;
        Tx_on       :   out STD_LOGIC;
        Tx			:	out STD_LOGIC);
end component;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--BROM
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    COMPONENT blk_mem_gen_0
        PORT (
            clka : IN STD_LOGIC;
            ena     : in std_logic;
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)  );
    END COMPONENT;


----+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
----calculator
----+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
component calculator is
PORT ( 	clk			: 	in 	STD_LOGIC;
		Sci_in		: 	in 	STD_LOGIC_VECTOR(7 downto 0);
		new_char    :   in  STD_LOGIC;
        Tx_done     :   in  STD_LOGIC;
        res			: 	out STD_LOGIC_VECTOR(9 downto 0);
        data_out    :   out STD_LOGIC);
end component;

--=============================================================
--Local Signal Declaration
--=============================================================
constant BAUD_PERIOD : integer := 44;
constant BIT_PERIOD : time := 8680 ns;


signal clk	    	: std_logic                     := '0';
signal Tx_new_data    : std_logic := '0';
signal Tx_char_in	    : std_logic_vector(7 downto 0) := (others => '0');
signal Tx_reset		: std_logic := '0';
signal Tx				: std_logic := '1';
signal Rx_reset		: std_logic := '0';
signal Rx			 	: std_logic := '0';
signal Rx_char_out    : std_logic_vector(7 downto 0) := (others => '0');
signal unconverted_res: std_logic_vector(9 downto 0) := (others => '0');
signal calc_out       : std_logic := '0';
signal converted_res  : std_logic_vector(15 DOWNTO 0) := (others => '0');

type lut_states is (idle, findAddr, wait1, wait2, send100, sending1001, sending1002, send10, sending101, sending102, send1, sending11, sending12);
signal next_state, cs : lut_states := idle;
--=============================================================
--Port Mapping + Processes:
--=============================================================
begin

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Timing:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++		
clocking: system_clock_generation
    port map (
        input_clk_port      => clk_ext_port,
        system_clk_port		=> clk
    );


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--sci_receiver:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
receiver: SCI_Rx
    port map (
      clk       => clk,
      reset		=> Rx_reset,
      New_data	=> RsRx_ext_port,
      Char_out	=> Rx_char_out,
      Rx		=> Rx
      );
        
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--sci_transmitter:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
transmitter: SCI_Tx
    port map (
      clk       => clk,
      reset		=> Tx_reset,
      Char_in	=> Tx_char_in,
      New_data	=> Tx_new_data,
      Tx_on		=> RsTx_ext_port,
      Tx		=> Tx
      );
      
--transmitter: SCI_Tx
--    port map (
--      clk       => clk,
--      reset		=> Tx_reset,
--      Char_in	=> Rx_char_out,
--      New_data	=> Rx,
--      Tx_on		=> RsTx_ext_port,
--      Tx		=> Tx
--      );

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--calculator
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
calculator_map: calculator
    PORT MAP ( 	
        clk		=> clk,
        Sci_in  => Rx_char_out,
        new_char => Rx,
        Tx_done => Tx,
        res      => unconverted_res,
        data_out => calc_out
      );



--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Block Memory
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
BCDlookup : blk_mem_gen_0
      PORT MAP (
        clka                => clk,
        ena                 => '1',
        addra               => unconverted_res,
        douta               => converted_res
      );
 
display_select: process(clk, Tx)
  begin
  
  if rising_edge(clk) then
    cs <= next_state;
  end if;
  
    Tx_new_data <= '0';
    next_state <= cs;
  
  case (cs) is

    when idle =>
        if calc_out = '1' then
            next_state <= findAddr;
        end if;
    when findAddr =>
        next_state <= wait1;
    when wait1 =>
        next_state <= wait2;
    when wait2 =>
        if Tx = '1' then
            next_state <= send100;
        end if;
    when send100 =>
        Tx_new_data <= '1';
        Tx_char_in <= std_logic_vector(resize(unsigned(converted_res(11 downto 8)),8) + 48);
        next_state <= sending1001;
    
    when sending1001 =>
        if Tx = '1' then
            next_state <= sending1002;
        end if;
    
    when sending1002 =>
        if Tx = '1' then
            next_state <= send10;
        end if;
        
    when send10 =>
        Tx_new_data <= '1';
        Tx_char_in <= std_logic_vector(resize(unsigned(converted_res(7 downto 4)),8) + 48);
        next_state <= sending101;
    
    when sending101 =>
        if Tx = '1' then
            next_state <= sending102;
        end if;
        
    when sending102 =>
        if Tx = '1' then
            next_state <= send1;
        end if;
        
    when send1 =>
        Tx_new_data <= '1';
        Tx_char_in <= std_logic_vector(resize(unsigned(converted_res(3 downto 0)),8) + 48);
        next_state <= sending11;
    
    when sending11 =>
        if Tx = '1' then
            next_state <= sending12;
        end if;
    
    when sending12 =>
        if Tx = '1' then
            next_state <= idle;
        end if;
    
  end case;
end process;

end Behavioral;
