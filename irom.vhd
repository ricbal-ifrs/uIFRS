----------------------------------------------
--! @file irom.vhd
--! @brief Memória (interna) de programa do uIF
--! @date abr-2024
--! @version 0.1
--! @author Ricardo Balbinot
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! @brief Memória ROM (programa) interna do uIF
--! @details Memória de 1024 posições, 16 bits por posição
--! @param clk Clock de entrada da memória
--! @param data Barramento de dados
--! @param addr Barramento de endereços de escrita
entity irom is
  port(
    clk: in std_logic;
	 data: out instruction;
	 addr: in std_logic_vector(romsize-1 downto 0)
  );
end irom;

architecture imp of irom is
  type memvetor is array (0 to 1023) of instruction;
  -- programa local, para testes
  -- comentar caso use o arquivo
  constant prog: memvetor := (
    0=> b"01_0001_000_000_00000000", -- andv r0,b00000000
    1=> b"01_0001_001_001_00000000", -- andv r1,b00000000
    2=> b"01_0001_010_010_00000000", -- andv r2,b00000000
    3=> b"00_0011_0000_0010000000", -- jmp 128
	 -- r3 é o padrão de pisca dos leds...
    128=> b"01_0001_011_011_00000000", -- andv r3,0
    129=> b"01_0011_011_011_10100101", -- orv r3,b10100101
	 -- inverte o padrão de pisca.... e refaz o loop inteiro
    130=> b"01_0011_000_000_00100000", -- orv r0,16
	 -- loop para tempo... R0
    131=> b"01_0011_001_001_11111111", -- orv r1,255
	 -- loop para tempo... R1
    132=> b"01_0011_010_010_11111111", -- orv r2,255
    133=> b"10_0101_011_000_00000000", -- out r3,0   
	 -- loop para consumo de tempo... R2
    134=> b"01_1011_010_010_00000001", -- subv r2,1 
    135=> b"00_0101_0000_0010000110", -- jpnz 134
    136=> b"01_1011_001_001_00000001", -- subv r1,1 
    137=> b"00_0101_0000_0010000100", -- jpnz 132
    138=> b"01_1011_000_000_00000001", -- subv r0,1
    139=> b"00_0101_0000_0010000011", -- jpnz 131 
    140=> b"01_0101_011_000_00000000", -- not r3
    141=> b"00_0011_0000_0010000010", -- jmp 130 
	 others=> x"00000"
  );
  
-- CORRIGIR CÓDIGO DE MÁQUINA DAS INSTRUÇÕES
--  constant prog: memvetor := (
--    0=> b"01_0001_000_000_11110000", -- or r0,r0,b11110000
--	 1=> b"10_0001_000_011_00000010", -- st r0,r3,2
--	 2=> b"01_0010_000_000_10101010", -- xor r0,r0,b10101010
--	 3=> b"01_0001_001_000_00001111", -- or r1,r0,b00001111
--	 4=> b"10_0000_001_011_00000010", -- ld r1,r3,2
--    5=> b"01_0000_000_000_00000000", -- and r0,r0,b00000000
--    6=> b"01_0000_001_001_00000000", -- and r1,r1,b00000000
--    7=> b"01_0000_010_010_00000000", -- and r2,r2,b00000000
--    8=> b"00_0001_0000_0010000000", -- call 128
--    9=> b"01_0000_000_000_00000000", -- and r0,r0,0
--    10=> b"01_0001_000_000_00001111", -- or r0,r0,b00001111
--    11=> b"10_0101_000_000_000000_00", -- out r0,0
--    12=> b"01_0011_000_000_00000000", -- not r0
--    13=> b"00_0100_0000_0000001011", -- jmp 11
--    128=> b"01_0000_000_000_00000000", -- and r0,r0,0
--    129=> b"01_0001_000_000_00000010", -- or r0,r0,b00000010
--    130=> b"01_0110_000_000_00000001", -- sub r0,r0,1 
--    131=> b"00_0110_0000_0010000010", -- jpnz 130
--    132=> b"00_0010_0000_0000000000", -- ret 
--	 others=> x"00000"
--  );

  
  signal mem: memvetor:= prog;
  
  -- programa em arquivo externo
  -- comentar caso use a constante com as instruções
  --signal mem: memvetor;
  -- carga inicial da memória no arquivo .mif a seguir
  -- isso é especifico da Intel Altera
  --attribute ram_init_file: string;
  --attribute ram_init_file of mem: signal is "programa.mif";
begin
  process(clk) 
  begin
    if (rising_edge(clk)) then
		data <= mem(to_integer(unsigned(addr)));
	 end if;
  end process;
end imp;