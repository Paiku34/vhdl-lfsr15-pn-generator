library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity PNG is
    generic (
        N: positive := 15
    );
    port (
        clk     : in std_logic;
        init    : in std_logic;
        IR      : in std_logic_vector (1 to N);
        reset   : in std_logic;
        PN_code : out std_logic_vector (1 to N)
    );
end entity;

architecture structural of PNG is
    Component D_flip_flop
    port (
        d       : in std_logic;   
        clk     : in std_logic; 
        reset   : in std_logic; 
        q       : out std_logic 
    );
    end component;

    Component Mux 
    port(
        x0      : in std_logic;
        x1      : in std_logic;
        sel     : in std_logic;
        z       : out std_logic
    );
    end component;

    signal qmux : std_logic_vector (1 to N);
    
    signal inXor : std_logic_vector (1 to 6);
    
    signal muxd : std_logic_vector (1 to N);
    
    signal outXor : std_logic_vector (1 to 5);

begin
    PNG_structure: for i in 1 to N generate

        FIRST: if i = 1 generate
            MX1: Mux port map( 
                    x0 => outXor(5),
                    x1 => IR(i),
                    sel => init,
                    z => muxd(i) 
                );
                      
            FF1 : D_flip_flop port map(
                    d => muxd(i),
                    clk => clk,
                    reset => reset,
                    q => qmux(i) 
                ); 
                    
            PN_code(i) <= qmux(i);
        end generate FIRST;

        INTERNAL: if i > 1 and i < N generate
            MXi: Mux port map( 
                    x0 => qmux(i-1),
                    x1 => IR(i),
                    sel => init,
                    z => muxd(i) 
                );
                  
            FFi : D_flip_flop port map(
                    d => muxd(i),
                    clk => clk,
                    reset => reset,
                    q => qmux(i) 
                ); 
                
            PN_code(i) <= qmux(i);  
        end generate INTERNAL;

        LAST: if i = N generate
            MXN: Mux port map( 
                    x0 => qmux(i-1),
                    x1 => IR(i),
                    sel => init,
                    z => muxd(i) 
                );
                        
            FFN : D_flip_flop port map(
                    d => muxd(i),
                    clk => clk,
                    reset => reset,
                    q => inXor(1) 
                ); 
                    
            PN_code(i) <= inXor(1);
        end generate LAST;
    
    end generate PNG_structure;

        OutPortXor1:          
            inXor(2) <= qmux(13);         
            outXor(1) <= inXor(1) xor inXor(2);
            -- -- inXor(1) <= q of last FFD;
            -- OutPortXor1 = q15 XOR q13;
         
        OutPortXor2:
            inXor(3) <= qmux(9);
            outXor(2) <= outXor(1) xor inXor(3);
            -- OutPortXor2 = OutPortXor1 XOR q9;
              
        OutPortXor3:
            inXor(4) <= qmux(8);
            outXor(3) <= outXor(2) xor inXor(4);   
            -- OutPortXor3 = OutPortXor2 XOR q8;
              
        OutPortXor4:
            inXor(5) <= qmux(7);
            outXor(4) <= outXor(3) xor inXor(5);   
            -- OutPortXor4 = OutPortXor3 XOR q7;
         
        OutPortXor5:
            inXor(6) <= qmux(5);
            outXor(5) <= outXor(4) xor inXor(6);     
            -- OutPortXor5 = OutPortXor4 XOR q5; 
    
end architecture structural;