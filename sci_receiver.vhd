----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Avery Widen
-- 
-- Create Date: 06/01/2022 05:37:05 PM
-- Design Name: 
-- Module Name: sci_transmitter - Behavioral
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

ENTITY SCI_Rx IS
PORT ( 	clk			: 	in 	STD_LOGIC;
		reset		:	in 	STD_LOGIC;
        New_data	:	in	STD_LOGIC;
        Char_out	: 	out	STD_LOGIC_VECTOR(7 downto 0);
        Rx			:	out STD_LOGIC);
end SCI_Rx;


ARCHITECTURE behavior of SCI_Rx is


--Datapath elements

constant BAUD_PERIOD : integer := 435; --Number of clock cycles needed to achieve a baud rate of 230,400 given a 100 MHz clock (100 MHz / 230400 = 435)
constant BAUD_PERIOD_HALF : integer := 218;
signal tc : std_logic := '0';
signal data1, data : std_logic := '1';

signal baud_count : integer range 0 to BAUD_PERIOD - 1 := BAUD_PERIOD - 1;
signal bit_count : integer range 0 to 9 := 0;
signal bit_reset : std_logic := '0';
--signal bit_length : integer range 0 to 15 := 0;
signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');
signal baud_tc : std_logic := '0';
signal load1: std_logic := '0';

signal shift_en, load_en : std_logic := '0';

type state_type is (idle, start, load, stop);
signal cs, ns : state_type := idle;

BEGIN

half_load : process(clk)
begin
	if rising_edge(clk) then
    -- put the data through 2 registers so there is no metastability
    	data1 <= New_data;
        data <= data1;
    end if;
end process half_load;

baud_generator : process(clk)
begin
	if rising_edge(clk) then
    	if (reset = '1') then
        	baud_tc <= '0';
            baud_count <= (BAUD_PERIOD - 1);
        else
        	if ((baud_count = 0) or load_en = '1') or load1 = '1' then
            	baud_tc <= '1';
                baud_count <= (BAUD_PERIOD - 1);
            else
            	baud_tc <= '0';
                baud_count <= baud_count - 1;
            end if;
        end if;
    end if;
end process baud_generator;

--BIT COUNTER
bitCount : process(clk)
begin
if rising_edge(clk) then
    if (reset = '1') or (bit_reset = '1') then
        bit_count <= 0;
    elsif (baud_tc = '1') and (shift_en = '1') then
        bit_count <= bit_count + 1;
    end if;
end if;
end process bitCount;


state_update : process(clk)
begin
	if rising_edge(clk) then
    	cs <= ns;
	end if;
end process state_update;

next_state_logic : process(cs, reset, data, baud_tc, bit_count, baud_count)
begin

    Rx <= '0';
    ns <= cs;
    shift_en <= '0';
    load_en <= '0';
    bit_reset <= '0';
    load1 <= '0';
    
    	if (reset = '1') then
        	ns <= idle;
        	
        else
          case cs is
               when idle =>
               
                    if data = '0' then -- start bit
                        ns <= start;
                        load_en <= '1';
                     end if;
        
               when start =>
                    load_en <= '1';
                    if baud_count = BAUD_PERIOD_HALF then
                        --load_en <= '1';
                        load1 <= '1';
                        ns <= load;
                    end if;
                    if data = '0' then
                        load_en <= '0';
                    end if;
        
                when load =>
                    shift_en <= '1';
                    if (bit_count = 9) and (data = '1') and (baud_tc = '1') then
                        ns <= stop;
                    end if;
            
               when stop =>
                    Rx <= '1';
                    bit_reset <= '1';
                    ns <= idle;
        
              when others => ns <= cs;
        end case;
    end if;
end process next_state_logic;

outputLogic: process(clk)
begin
if rising_edge(clk) then
    if shift_en = '1' and baud_tc = '1' then
        shift_reg <= data & shift_reg(9 downto 1);
    end if;
end if;
end process;

 Char_out <= shift_reg(8 downto 1);

end behavior;


