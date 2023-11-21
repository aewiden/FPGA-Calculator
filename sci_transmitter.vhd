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

ENTITY SCI_Tx IS
PORT ( 	clk			: 	in 	STD_LOGIC;
		reset		: 	in	STD_LOGIC;
		Char_in		: 	in 	STD_LOGIC_VECTOR(7 downto 0);
        New_data	:	in	STD_LOGIC;
        Tx_on       :   out STD_LOGIC;
        Tx			:	out STD_LOGIC);
end SCI_Tx;


ARCHITECTURE behavior of SCI_Tx is


--Datapath elements
constant BAUD_PERIOD : integer := 435; --Number of clock cycles needed to achieve a baud rate of 230,400 given a 100 MHz clock (100 MHz / 230400 = 435)

--baud and bit counters
signal baud_tc : std_logic := '0';
signal baud_count : integer range 0 to BAUD_PERIOD - 1 := BAUD_PERIOD - 1;
signal bit_count : integer range 0 to 9 := 0;
signal bit_reset : std_logic := '0';

signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');

signal load_en, shift_en   : std_logic := '0';

--start proc
signal start_bit : std_logic := '0';
signal start_reset : std_logic := '0';

--fsm signals
type state_type is (idle, start, load, stop);
signal cs, ns : state_type := idle;


BEGIN

--START TRANSMISSION
start_proc : process(clk)
begin
if rising_edge(clk) then
    if (reset = '1') or (start_reset = '1') then
        start_bit <= '0';
    else
        if (new_data = '1') and (start_bit = '0') then
            start_bit <= '1';
        end if;
    end if;
end if;
end process start_proc;


--BAUD COUNTER
baud_generator : process(clk, baud_count)
begin
if rising_edge(clk) then
    if (reset = '1') then
        baud_tc <= '0';
        baud_count <= BAUD_PERIOD - 1;
    else

        if (baud_count = 0 or load_en = '1') then
            baud_tc <= '1';
            baud_count <= BAUD_PERIOD - 1;
        else
            baud_tc <= '0';
            baud_count <=baud_count - 1;
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
    elsif (baud_tc = '1') and shift_en = '1' then
        bit_count <= bit_count + 1;
    end if;
end if;
end process bitCount;

--FSM
state_update : process(clk)
begin
if rising_edge(clk) then
    cs <= ns;
end if;
end process state_update;

next_state_logic : process(cs, start_bit, reset, bit_count, shift_reg, baud_tc, baud_count)
begin
Tx <= '1';
load_en <= '0';
shift_en <= '0';
ns <= cs;
bit_reset <= '0';
start_reset <= '0';

if (reset = '1') then
    ns <= idle;
    bit_reset <= '1';
    start_reset <= '1';
    Tx <= '1';
else
    case cs is
        when idle =>
            
            if (New_data = '1') then
                ns <= start;
            else
                ns <= idle;
            end if;
            
        when start =>
            load_en <= '1';
            Tx <= '0';
            ns <= load;
       
        when load =>
            Tx <= '0';
            shift_en <= '1';
            if (bit_count = 10) and baud_tc = '1' then
                ns <= stop;
            end if;
            
        when stop =>
            Tx <= '1';
            start_reset <= '1';
            bit_reset <= '1';
            ns <= idle;
            
        when others =>
            ns <= cs;
        end case;
end if;
end process next_state_logic;

--OUTPUT LOGIC
outputLogic : process(clk)
begin

if rising_edge(clk) then

    if load_en = '1' then
--        shift_reg <= '1' & char_in(7 downto 0) & '0';
        shift_reg <= '1' & char_in & '0';
    elsif shift_en = '1' and baud_tc = '1' and bit_count > 0 then
        shift_reg <= '1' & shift_reg(9 downto 1);
    end if;

end if;

end process;

Tx_on <= shift_reg(0);

end behavior;
        
        
        