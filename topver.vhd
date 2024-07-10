----------------------------------------------
--! @file topver.vhd
--! @brief Entidade topo de verificação do uIF
--! @date abr-2024
--! @version 0.1
--! @author Ricardo Balbinot
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

-- top entity
entity topver is
  port(
    clk, rst: in std_logic;
	 inputs: in std_logic_vector(7 downto 0);
	 outputs: out std_logic_vector(7 downto 0)
  );
end topver;

architecture imp of topver is
  signal datawrite: std_logic_vector(data_size-1 downto 0);
  signal dataread: std_logic_vector(data_size-1 downto 0);
  signal ramwe: std_logic;
  signal ramaddrwrite, ramaddrread: std_logic_vector(ramsize-1 downto 0);
  signal instr: instruction;
  signal instr_addr : std_logic_vector(romsize-1 downto 0);
  signal saidas: std_logic_vector(31 downto 0);
  signal entradas: std_logic_vector(31 downto 0);
begin
  -- sinais de I/O
  outputs<=saidas (7 downto 0);
  entradas(7 downto 0) <= inputs;
  entradas(7 downto 0) <= inputs;
  entradas(31 downto 8) <= (others=>'0');

  ram: entity work.iram(imp) port map(clk=>clk, datain=> datawrite, dataout=>dataread,
       we=> ramwe, waddr=> ramaddrwrite, raddr=> ramaddrread);		 
  rom: entity work.irom(imp) port map(clk=> clk, data=>instr, addr=>instr_addr);

  micro: entity work.uIF(imp) port map(
    clk=>clk,
	 rst=>rst,
	 datain=> dataread,
	 dataout=> datawrite,
	 we=>ramwe,
	 waddr=> ramaddrwrite,
	 raddr=> ramaddrread,
	 progdata=> instr,
	 progaddr=> instr_addr,
	 isignals=> entradas,
	 osignals=> saidas
	 );
end imp;

