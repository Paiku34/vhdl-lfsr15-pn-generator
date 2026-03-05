library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity Mux is
    port(
        x0  : in std_logic;
        x1  : in std_logic;
        sel : in std_logic;
        z   : out std_logic
    );
end entity;

architecture beh of Mux is

    begin
        P_mux : process (x0, x1, sel)
        begin
            if (sel = '0') then
                z <= x0;
            elsif (sel ='1') then
                z <= x1;
            end if;
        end process P_mux;

    end architecture;