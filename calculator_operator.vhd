----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/02/2022 10:30:49 AM
-- Design Name: 
-- Module Name: calculator_operator - Behavioral
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY calculator  IS
PORT ( 	clk			: 	in 	STD_LOGIC;
		Sci_in		: 	in 	STD_LOGIC_VECTOR(7 downto 0);
		new_char    :   in  STD_LOGIC;
        Tx_done     :   in  STD_LOGIC;
        res			: 	out STD_LOGIC_VECTOR(9 downto 0);
        data_out    :   out STD_LOGIC);
end calculator;


ARCHITECTURE behavior of calculator is

constant BAUD_PERIOD : integer := 435; --Number of clock cycles needed to achieve a baud rate of 230,400 given a 100 MHz clock (100 MHz / 230400 = 435)

--INTERMEDIATE SIGNALS
signal load_en, clear_en, t1_en, t1_reset_en, t2_en, res_en, new_calc_en : std_logic;
signal t1,t2 : std_logic_vector(9 downto 0) := (others => '0');
signal prev_res : std_logic_vector(9 downto 0) := (others => '0');
signal input: unsigned(9 downto 0) := (others => '0');
signal clear_input : std_logic := '0';
signal res_displayed : std_logic := '0';
signal t2_displayed : std_logic := '0';
signal waiting  : std_logic := '0';
signal data_out_res : std_logic := '0';
signal transmit_op : std_logic := '0';
signal tx_count : integer := 0;

--STATE SIGNALS
type state_type is (wait1, load1, wait2, load2, waitTx, finalRes, newCalc, waitNext);
signal CS,NS : state_type := wait1;

--OPERATOR SIGNALS
signal op: std_logic_vector(1 downto 0) := "11";
signal new_op : std_logic_vector(1 downto 0) := "11";
signal equals: std_logic;
signal op_equals: std_logic;
signal num: std_logic;
signal updated: std_logic;


begin

txCount: process(clk)
begin

if rising_edge(clk) then
    if transmit_op = '1' then
        if tx_count = 32*(BAUD_PERIOD)+1 then
            tx_count <= 0;
        else
            tx_count <= tx_count + 1;
        end if;
    end if;
end if;


end process;



--FSM
stateUpdate: process(clk)
begin

if rising_edge(clk) then
	CS <= NS;
end if;

end process;

nextStateLogic: process(CS, load_en, clear_en, new_char, new_calc_en, tx_count, Tx_done)
begin

NS <= CS;

case (CS) is
	when wait1 =>
    	if load_en = '1' then
        	NS <= load1;
        end if;
        
    when load1 =>
    	NS <= wait2;
    
    when wait2 => 
    	if load_en = '1' then
        	NS <= load2;
        end if;
    
    when load2 =>
    	NS <= waitTx;
    	
    when waitTx =>
        if tx_count > 32*BAUD_PERIOD and Tx_done = '1' then
            NS <= finalRes;
        end if;
    
    when finalRes =>
        NS <= waitNext;

    when waitNext =>
        if num = '1' then
        	NS <= wait1;
        elsif op_equals = '1' then
            NS <= newCalc;
        end if;

    when newCalc =>
        NS <= wait2;
    
	when others =>
    	NS <= CS;
end case;

end process;

outputLogic: process(CS) 
begin

t1_en <= '0';
t2_en <= '0';
res_en <= '0';
clear_input <= '0';
t1_reset_en <= '0';
t2_displayed <= '0';
waiting <= '0';
transmit_op <= '0';
--data_out2 <= '0';
--data_out1 <= '0';

case (CS) is
	when wait1 =>
        
    when load1 =>
		t1_en <= '1';
        clear_input <= '1';
        
    when wait2 =>
    	t2_displayed <= '1';
    
    when load2 =>
        t2_en <= '1';        
        clear_input <= '1';
    
    when waitTx =>
        transmit_op <= '1';
            
    when finalRes =>
		res_en <= '1';
        data_out_res <= '1';
	
	when waitNext =>
	   waiting <= '1';
	
    when newCalc =>
        t1_reset_en <= '1';
end case;

end process;



--ASCII CONVERSION
asciiConversion: process(Sci_in, clk, res_displayed, new_char, t2_displayed, waiting, op_equals, t2_en)
begin

load_en <= '0';
new_calc_en <= '0';

--ascii number conversion
if rising_edge(clk) then
  if (new_char = '1') then
        num <= '0';
        equals <= '0';
        op_equals <= '0';
        
        if ((unsigned(Sci_in) > 47 and unsigned(Sci_in) < 58)) then
          input <= resize(input*10,10) + resize((unsigned(Sci_in)-48),10);
          num <= '1';
          
        elsif (unsigned(Sci_in) = 10) then
            equals <= '1';
          
        elsif (unsigned(Sci_in) = 42 or unsigned(Sci_in) = 43 or unsigned(Sci_in) = 45) then
            if t2_displayed = '1' or waiting = '1' then
                op_equals <= '1';
            end if;
        end if;
  end if;
  
  --clearing for next load
  if clear_input = '1' then
      input <= (others => '0');
  end if;
  
end if;


--equals handling
if (new_char = '1' and unsigned(Sci_in) = 10) then
    equals <= '1';
    load_en <= '1';
--  res <= std_logic_vector(resize((unsigned(Sci_in)-48),10));
	
--operator handling
elsif new_char = '1' and (unsigned(Sci_in) = 42 or unsigned(Sci_in) = 43 or unsigned(Sci_in) = 45) then
    
	if t2_displayed = '1' or waiting = '1' then
    
        if unsigned(Sci_in) = 42 then 		--multiplication
            new_op <= "00";
        elsif unsigned(Sci_in) = 43 then 	--addition
            new_op <= "01";
        elsif unsigned(Sci_in) = 45 then	--subtraction
            new_op <= "10";
        end if;
           
    elsif t2_en = '0' then
        --new_op <= op;

        if unsigned(Sci_in) = 42 then 		--multiplication
            op <= "00";
        elsif unsigned(Sci_in) = 43 then 	--addition
            op <= "01";
        elsif unsigned(Sci_in) = 45 then	--subtraction
            op <= "10";
        end if;
            
    end if;
    
	load_en <= '1';
--    res <= std_logic_vector(resize((unsigned(Sci_in)-48),10));

--elsif (new_char = '1' and (unsigned(Sci_in) > 47 and unsigned(Sci_in) < 58)) then
--  res <= std_logic_vector(input); 
end if;

--op <= op;
if waiting = '1' and op_equals = '1' then
    op <= new_op;
    updated <= '1';
else
    updated <= '0';
end if;

end process;


--DATAPATH

datapath: process(clk,new_char ,res_en, data_out_res)
begin

if rising_edge(clk) then

    -- clearing (not implemented yet)
    if clear_en = '1' then
        t1 <= (others => '0');
        t2 <= (others => '0');
--        res <= (others => '0');
    
    -- serial calculations
    elsif t1_reset_en = '1' then
        t1 <= prev_res;
    
    -- t1
    elsif t1_en = '1' then
        t1 <= std_logic_vector(input);
--        res <= t1;
    
    -- t2
    elsif t2_en = '1' then
        t2 <= std_logic_vector(input);
    
    end if;
    
    -- calculating results
    if res_en = '1' then
    
        if op = "00" then
          res <= std_logic_vector(resize(unsigned(t1) * unsigned(t2),10));
          prev_res <= std_logic_vector(resize(unsigned(t1) * unsigned(t2),10));
        elsif op = "01" then
          res <= std_logic_vector(resize(unsigned(t1),10) + resize(unsigned(t2),10));
          prev_res <= std_logic_vector(resize(unsigned(t1),10) + resize(unsigned(t2),10));
        elsif op = "10" then
          res <= std_logic_vector(resize(unsigned(t1),10) - resize(unsigned(t2),10));
          prev_res <= std_logic_vector(resize(unsigned(t1),10) - resize(unsigned(t2),10));
        end if;
    end if;
end if;

if new_char = '1' and res_en = '0' then
    data_out <= '1';
    res <= std_logic_vector(resize((unsigned(Sci_in)-48),10));
elsif res_en = '1' then
    data_out <= data_out_res;
else 
    data_out <= '0';
end if;


end process;



end behavior;