----------------------------------------------
--! @file uIFDefs.vhd
--! @brief Definições globais do uIF
--! @date mai-2024
--! @version 0.2
--! @author Ricardo Balbinot
----------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uIFDefs is
-- barramentos
constant data_size: integer := 8; --! tamanho do barramento de dados
constant inst_size: integer := 20; --! tamanho do barramento de instruções 

-- registradores
constant reg_qtd: integer:= 8; --! quantidade de registradores internos
subtype reg_sel is unsigned(2 downto 0);
subtype reg_word is std_logic_vector(data_size-1 downto 0); --! tamanho de um registrador

-- tamanhos das memorias
constant romsize: integer:= 10; -- tamanho da memoria ROM (2^)
constant ramsize: integer:= 8; -- tamanho da memoria RAM (2^)

-- quantidade de pinos de I/O
constant io_size: integer:= 32; --! quantidade de pinos de I/O

-- UNIDADE DE CONTROLE
type controlstates is (busca,decodifica,recupera_stack,executa,atualiza); --! Estados do controlador

-- instruções (opcode)
subtype instruction is std_logic_vector(inst_size-1 downto 0);
subtype instr_type is std_logic_vector(1 downto 0);
subtype instr_subtype is std_logic_vector(3 downto 0);
subtype reg_subtype is std_logic_vector(2 downto 0);

-- controle (inicia em 00) 
constant controlcode: instr_type:= "00"; --! opcode do conjunto de instruções de controle do fluxo de execuç~ao
subtype control_type is instr_subtype; --! opcodes espec´ificos de controle
-- nop               -- 00_0000
constant nopcode: control_type:= "0000"; --! @brief Opcode da instruç~ao nop 
                                         --! @details Nenhuma operaç~ao
-- call addr			-- 10_0000
constant callcode: control_type:= "0001"; --! @brief Opcode da instruç~ao call addr
                                          --! @details PC<-addr; stack<-PC+1
-- ret					-- 10_0101
constant retcode: control_type:= "0010"; --! opcode da instruç~ao ret
-- jmp addr	   		-- 10_0110
constant jmpcode: control_type:= "0100"; --! opcode da instruç~ao jmp addr
-- jpz addr          -- 10_0111
constant jpzcode: control_type:= "0101"; --! opcode da instruç~ao jpz addr
-- jpnz addr         -- 10_1000
constant jpnzcode: control_type:= "0110"; --! opcode da instruç~ao jpnz addr
-- jpc addr          -- 10_1001
constant jpccode: control_type:= "0111"; --! opcode da instruç~ao jpc addr
-- jpnc addr         -- 10_1010
constant jpnccode: control_type:= "1000"; --! opcode da instruç~ao jpnc addr


--! Opcode do conjunto de instruç~oes da ULA
constant ulacode: instr_type:= "01";

--! Subtipo que identifica os opcodes espec´ificos de operaç~oes com o bloco da ULA
subtype ula_type is instr_subtype;

--! @brief Opcode da instrução and r1,r2
--! @details Realiza a operaç~ao r1<- r1 and r2
--! @warning Afeta o flag Z
constant andcode: ula_type:= "0000"; 

--! @brief Opcode da instrução and r1,val
--! @brief Realiza a operaç~ao r1<- r1 and val
--! @warning Afeta o flag Z
constant andvcode: ula_type:= "0001"; 

--! @brief Opcode da instrução or r1,r2,val (00_0010)
--! @details Realiza a operaç~ao r1<- r1 or r2
--! @warning Afeta o flag Z
constant orcode: ula_type:= "0010"; 

--! @brief Opcode da instrução orv r1,val (00_0011)
--! @details Realiza a operaç~ao r1<- r1 or val
--! @warning Afeta o flag Z
constant orvcode: ula_type:= "0011"; 
                           
--! @brief Opcode da instruç~ao xor r1,r2
--! @details Realiza a operaç~ao r1<- r1 xor r2
--! @warning Afeta o flag Z
constant xorcode: ula_type:= "0100";

--! @brief Opcode da instruç~ao not r1
--! @brief Realiza a operaç~ao r1<- not r1
--! @warning Afeta o flag Z
constant notcode: ula_type:= "0101"; 

--! @brief Opcode da instruç~ao add r1,r2
--! @details Realiza a operaç~ao r1<- r1+r2 (soma sem carry)
--! @warning Afeta os flags Z, S e C
constant addcode: ula_type:= "0110";

--! @brief Opcode da instruç~ao addc r1,r2
--! @detailt Realiza a operaç~ao r1<- r1+r2+C (soma com ´ultimo carry gerado)
--! @warning Afeta os flags Z, S e C
constant addccode: ula_type:= "0111";

--! @brief Opcode da instruç~ao addv r1,val  (soma com valor)
--! @detailt Realiza a operaç~ao r1<- r1+val (soma com ´ultimo carry gerado)
--! @warning Afeta os flags Z, S e C
constant addvcode: ula_type:= "1000";

--! @brief Opcode da instruç~ao sub r1,r2
--! @details Realiza a operaç~ao r1<-r1-r2
--! @warning Afeta os flags Z, S e C
constant subcode: ula_type:= "1001"; 

--! @brief Opcode da instruç~ao subc r1,r2
--! @details Realiza a operaç~ao r1<-r1-r2-C
--! @warning Afeta os flags Z, S e C
constant subccode: ula_type:= "1010"; 

--! @brief Opcode da instruç~ao subv r1,val
--! @details Realiza a operaç~ao r1<-r1-val
--! @warning Afeta os flags Z, S e C
constant subvcode: ula_type:= "1011"; 

--! @brief Opcode da instruç~ao shl r1,cnt
--! @details Realiza a operaç~ao r1(n+1)<-r1(n); r1(0)<-0
--! @warning Afeta os flags Z e S
constant shlcode: ula_type:= "1100";

--! @brief Opcode da instruç~ao shr r1,cnt
--! @details Realiza a operaç~ao r1(n)<-r1(n+1); r1(7)<-0
--! @warning Afeta os flags Z e S
constant shrcode: ula_type:= "1101";

--! @brief Opcode da instruç~ao rol r1,cnt
--! @details Realiza a operaç~ao r1(n+1)<- r1(n); r1(0)<- r1(7)
--! @warning Afeta os flags Z, S
constant rolcode: ula_type:= "1110"; 

--! @brief Opcode da instruç~ao ror r1,cnt
--! @details Realiza a operaç~ao r1(n)<-r1(n+1); r1(7)<-r1(0)
--! @warning Afeta os flags Z e S
constant rorcode: ula_type:= "1111"; 

-- memoria e I/O (inicia em 10)		
constant memorycode: std_logic_vector(1 downto 0):= "10"; --! opcode do conjunto de instruções de manipulação dos registradores
subtype memory_type is instr_subtype;
-- ld r1,r2,offset	-- 01_0000
constant ldcode: memory_type:= "0000"; --! opcode da instruçao ld r1,r2,offset
-- pensar em uma carga de memoria "distante"?? usando todo o espaço possivel...
-- st r1,r2,offset	-- 01_0001
constant stcode: memory_type:= "0001"; --! opcode da instruçao st r1,r2,offset
-- in r1,port			-- 01_0100
constant incode: memory_type:= "0100"; --! opcode da instruç~ao in r1,port
-- out r1,port			-- 01_0101
constant outcode: memory_type:= "0101"; --! opcode da instruç~ao out r1,port

-- miscel^anea (inicia em 11)





end package;


