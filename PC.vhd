----------------------------------------------
--! @file PC.vhd
--! @brief Program Counter (Datapath)
--! @date abr-2024
--! @version 0.1
--! @author Ricardo Balbinot
----------------------------------------------

----------------------------------------------
-- PROGRAM COUNTER
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! Entidade representando o registrador program counter e a lógica associada
entity pgrCounter is
  port(
    clk: in std_logic; --! Sinal de clock geral
	 rst: in std_logic; --! Sinal de reset geral
	 addr: out unsigned(romsize-1 downto 0); --! Endereço indicado pelo PC
    nextaddr: out unsigned(romsize-1 downto 0); --! Próxima posição do PC
	 pstate: in controlstates; --! Dados de controle do núcleo do processador para operação do PC
    jump: in boolean; --! Indica se deve operar de acordo com alguma instrução de controle do PC
    cflag: in std_logic; --! Flag de carry, usado para decisões de salto
    zflag: in std_logic; --! Flag de zero, usado para decisões de salto
    condition: in control_type; --! Opcode da operação de salto
    jmpaddr: in unsigned(romsize-1 downto 0) --! Endereço absoluto de memória, associado a eventual salto
  );
end pgrCounter;

architecture imp of pgrCounter is
  signal PC: unsigned(romsize-1 downto 0);
  signal PCinput: unsigned(romsize-1 downto 0);
begin
  addr<= PC;
  -- atualizacao do PC
  process(clk,rst,pcinput)
  begin
    if (rst='1') then
	   PC <= (others=>'0');
	 elsif rising_edge(clk) then
	   if (pstate=executa) then
  	     PC <= PCinput;
		end if;
	 end if;
  end process;
  
  -- definicao do novo PC
  process(PC,jump,condition,jmpaddr,cflag,zflag)
    variable nextPC: unsigned(romsize-1 downto 0);
  begin
    -- aqui, no futuro, associar a um circuito direto de incremento
	 -- situação normal de operação do PC
    nextPC:= PC+1;
	 -- continuando o codigo de controle do PC  
    PCInput<= nextPC;
    if (jump) then 
      case condition is 
        when jmpcode =>
          PCInput<= jmpaddr;
        when jpzcode =>
          if (zflag='1') then
            PCInput<= jmpaddr;
          end if;
        when jpnzcode =>
          if (zflag='0') then
            PCInput<= jmpaddr;
          end if;
        when jpccode =>
          if (cflag='1') then
            PCInput<= jmpaddr;
          end if;
        when jpnccode =>
          if (cflag='0') then 
            PCInput<= jmpaddr;
          end if;
        when callcode|retcode=>
          PCInput<= jmpaddr;
        when others =>
      end case;
    end if;
	 nextaddr<= nextPC;
  end process;
end imp;