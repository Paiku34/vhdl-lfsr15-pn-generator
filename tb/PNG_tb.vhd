library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PNG_tb is 
end entity;

architecture beh of PNG_tb is 

    component PNG 
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
    end component;

    constant clk_period : time      := 10 ns;
    constant TestLen    : positive  := 66000;
    constant N          : positive  := 15;

    SIGNAL clk_ext : std_logic := '0';  
  
    SIGNAL init_ext : std_logic := '1'; 
    -- init to 1 (sel = 1 to all of the 15 mux)
  
    signal IR_ext : std_logic_vector (1 to N):= "000000000000001";
    -- This seed is chosen. With this seed we can generate a maximum sequence which is = 2^15 - 1 = 32768 
  
    signal reset_ext : std_logic := '0'; 
    --flip flop deactivated, i 15 q to zero

    signal PNcode_ext : std_logic_vector (1 to N);
  
    signal clk_cycle : integer; -- clock counter
    signal Testing : Boolean := True; 

    begin 
        clk_ext <= not clk_ext after clk_period/2 when testing else '0';
        
    c_DUT: PNG
        generic map(
            N => 15
        )
        port map(
            clk => clk_ext,
            init => init_ext,
            IR => IR_ext,
            reset => reset_ext,
            PN_code => PNcode_ext
        );

    Test_Proc : PROCESS (clk_ext)
               
        variable count : INTEGER := 0;
                
        BEGIN
            clk_cycle <= (count+1)/2;
                  
            case count is 
                when 3 => reset_ext <= '1';

                when 10 => init_ext <= '0';

                when (TestLen-1) => Testing <= False; 
                
                when others => NULL;
            end case;
           
        count := count + 1;
                      
    end Process Test_Proc;

end architecture;
