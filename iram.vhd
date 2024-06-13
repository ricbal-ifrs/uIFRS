----------------------------------------------
--! @file iram.vhd
--! @brief Memória (interna) de dados do uIF
--! @date abr-2024
--! @version 0.1
--! @author Ricardo Balbinot
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! @brief Memória RAM interna do uIF
--! @details Memória de 256 posições, 8 bits por posição
--! com barramentos separados de leitura/escrita, capaz
--! de escrever ao mesmo tempo que lê, porém com leitura
--! antes da escrita 
--! @param clk Clock de entrada da memória
--! @param datain Barramento de dados de entrada
--! @param dataout Barramento de dados de saída
--! @param we Habilitação de escrita (alta) ou leitura (baixa)
--! @param waddr Barramento de endereços de escrita
--! @param raddr Barramento de endereços de leitura
entity iram is
  port(
    clk: in std_logic;
	 datain: in std_logic_vector(data_size-1 downto 0);
	 dataout: out std_logic_vector(data_size-1 downto 0);
	 we: in std_logic;
	 waddr: in std_logic_vector(ramsize-1 downto 0);
	 raddr: in std_logic_vector(ramsize-1 downto 0)
  );
end iram;

architecture imp of iram is
  type memvetor is array (0 to 255) of std_logic_vector(7 downto 0);
  signal mem: memvetor;
begin
  process(clk) 
  begin
    if (rising_edge(clk)) then
	   if (we='1') then 
		  mem(to_integer(unsigned(waddr)))<= datain; 
		end if;
		dataout <= mem(to_integer(unsigned(raddr)));
	 end if;
  end process;
end imp;

