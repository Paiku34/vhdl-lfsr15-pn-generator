library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity D_flip_flop is 
    port(
        d       : in std_logic;
        clk     : in std_logic;
        reset   : in std_logic;
        q       : out std_logic
    );
end entity;

architecture beh of D_flip_flop is
    
    begin
        P_dff : process (clk, reset) 
        begin             
            if (reset = '0') then 
                q <= '0';       
            elsif (rising_edge(clk)) then 
                q <= d;   
            end if;   
        end process P_dff;
 
end architecture;