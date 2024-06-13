----------------------------------------------
--! @file Datapath.vhd
--! @brief Elementos do datapath do uIF
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

--! Entidade representando o PC
entity pgrCounter is
  port(
    clk: in std_logic; --! Sinal de clock geral
	 rst: in std_logic; --! Sinal de reset geral
	 addr: out unsigned(romsize-1 downto 0); --! Endereço indicado pelo PC
    nextaddr: out unsigned(romsize-1 downto 0); --! Pr´oxima posiç~ao do PC
	 pstate: in controlstates; --! Dados de controle para operacao do PC
    jump: in boolean; --! Indica se deve operar de acordo com alguma instriç~ao de controle do PC
    cflag: in std_logic; --! Flag de carry, usado para decis~oes de salto
    zflag: in std_logic; --! Flag de zero, usado para decis~oes de salto
    condition: in control_type; --! Opcode da operaç~ao de salto
    jmpaddr: in unsigned(romsize-1 downto 0) --! Endereço absoluto de mem´oria
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
    nextPC:= PC+1;
    nextaddr<= nextPC;  
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
  end process;
end imp;

----------------------------------------------
-- M´ODULO DE I/O
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! M´odulo de I/O (32 pinos de entrada e 32 pinos de sa´ida, com uso independente)
entity iomodule is
  port(    
    clk: in std_logic; --! sinal de clock 
	 rst: in std_logic; --! sinal de reset geral
	 pstate: in controlstates; -- ! sinal de controle
    is_instr_memory: in boolean; --! indica que a instruç~ao considerada trata com io
    opcode: in memory_type; --! c´odigo da instruç~ao
    ioblock: in std_logic_vector(data_size-1 downto 0); -- seleç~ao do bloco de io
    isignals: in std_logic_vector(io_size-1 downto 0); -- sinais de entrada externos
    osignals: out std_logic_vector(io_size-1 downto 0); -- sinais de sa´ida externos
    writesignal: in reg_word; --! sinal de leitura de um registrador
    readsignal: out reg_word -- ! sinal de entrada selecionado
  );
end iomodule;

architecture imp of iomodule is
  signal inlatch: std_logic_vector(io_size-1 downto 0);
  signal inbuffer: std_logic_vector(io_size-1 downto 0);
  signal outbuffer: std_logic_vector(io_size-1 downto 0);
begin
  -- latch de entrada de sincronismo
  -- para evitar metaestabilidade de o sinal do pinos
  -- f´isico de I/O sofre alteraç~oes pr´oximo a borda de subida do registrador de entrada
  -- amostra o sinal no in´icio do clico de busca
  process(clk)
  begin
    if (clk='1') then
      if (pstate=busca) then 
        inlatch<= isignals;
      end if;
    end if;
  end process;
  
  -- buffer dos sinais de entrada
  -- toma o sinal do latch ap´os a amostragem (ciclo de decodificaç~ao)
  process(clk, rst)
  begin
    if (rst='1') then
	   inbuffer<= (others=>'0');
    elsif (rising_edge(clk)) then
        inbuffer<= inlatch;
    end if;
  end process;
  
  -- mux de seleç~ao do bloco do buffer de I/O
  process(inbuffer,pstate,is_instr_memory,opcode,ioblock)
  begin
    readsignal<= (others=>'0');
    if (pstate=executa) and (is_instr_memory) and (opcode=incode) then
      case ioblock(1 downto 0) is
        when "00" =>
          readsignal<= inbuffer(7 downto 0);
        when "01" =>
          readsignal<= inbuffer(15 downto 8);
        when "10" =>
          readsignal<= inbuffer(23 downto 16);
        when others =>
          readsignal<= inbuffer(31 downto 24);
      end case;
	 end if;
  end process;
  
  -- atualizaç~ao (se for o caso) do buffer de sinais de sa´ida
  process(clk,rst,outbuffer) 
  begin
    if (rst='1') then
      outbuffer<= (others=>'0');
    elsif rising_edge(clk) then
      if (pstate=atualiza) and (is_instr_memory) and (opcode=outcode) then
        case ioblock(1 downto 0) is
          when "00" =>
            outbuffer(7 downto 0)<= writesignal;
          when "01" =>
            outbuffer(15 downto 8)<= writesignal;
          when "10" =>
            outbuffer(23 downto 16)<= writesignal;
          when others =>
            outbuffer(31 downto 24)<= writesignal;
        end case;
      end if;
    end if;
    osignals<= outbuffer;
  end process;
end imp;

----------------------------------------------
-- Mux de entrada do GPR
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! Registrador de leitura da mem´oria SRAM com MUX de seleç~ao e interface com sistema de I/O
entity gprmux is
  port(
    clk: in std_logic; --! sinal de clock 
	 rst: in std_logic; --! sinal de reset geral
	 pstate: in controlstates; -- ! sinal de controle
    is_instr_memory: in boolean; --! indica que a instruç~ao considerada trata com a mem´oria ou io
    is_instr_ula: in boolean; -- ! indica que a instruç~ao considerada trata com a ULA
    opcode: in instr_subtype; --! c´odigo da instruç~ao
    ula_input: in reg_word; --! entrada de dados do registrador da ULA
    ram_input: in reg_word; --! entrada de dados de leitura da SRAM
    io_input: in reg_word; --! entrada de dados do m´odulo de I/O
    reg_update: out boolean; --! indica se os registradores devem ser atualizados
    reg_data: out reg_word  --! dado para atualizaç~ao dos registradores
  );
end gprmux;

architecture imp of gprmux is
begin 
  -- mux de seleç~ao dos dados para atualizaç~ao dos registradores
  process(pstate,ula_input,ram_input,io_input,is_instr_ula,is_instr_memory,opcode) 
  begin
    reg_update<= false;
	 reg_data<= (others=>'0');
	 if (pstate=executa) or (pstate=atualiza) then -- mant´em os valores nos estados executa e atualiza
		if (is_instr_ula) then
		  reg_update<= true;
		  reg_data<= ula_input;
		elsif (is_instr_memory) then
		  if (opcode=ldcode) then 
          reg_update<= true;
          reg_data<= ram_input;
        elsif (opcode=incode) then
          reg_update<= true;
          reg_data<= io_input;
        end if;
      end if;
	 end if;
  end process;
end imp;

----------------------------------------------
-- GENERAL PURPOSE REGISTER
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! Registradores de proposito geral(GPR)
entity gpr is
  port(
    clk: in std_logic; --! sinal de clock 
	 rst: in std_logic; --! sinal de reset geral
	 pstate: in controlstates; -- ! sinal de controle
	 datai: in reg_word; --! entrada de atualizacao dos registradores
	 in_sel: reg_sel; --! indicaçao do registrador a ser atualizado
	 in_update: boolean; --! sinal de controle para indicar se algum registrador deve ser atualizado
	 r1_sel: in reg_sel; --! seleçao do registrador r1
	 r2_sel: in reg_sel; --! selecao do registrador r2
	 r1: out reg_word; --! valor do registrador r1
	 r2: out reg_word --! valor do registrador r2
  );
end gpr;

architecture imp of gpr is
  type reg_array is array (0 to reg_qtd-1) of reg_word;
  signal regs: reg_array;
  signal reg_input: reg_word;
  signal reg_sel: integer range 0 to reg_qtd-1;
begin
  -- reflete na saida os registradores solicitados como R1 e R2
  r1<= regs(to_integer(r1_sel));
  r2<= regs(to_integer(r2_sel));
  -- registradores internos(8 registradores)
  process(clk,rst)
  begin 
    if (rst='1') then
      regs<= (others=>(others=>'0'));
	 elsif (rising_edge(clk)) then
	   if (pstate=atualiza) and (in_update) then 
	     regs(to_integer(in_sel)) <= datai;
		end if;
	 end if;
  end process;
end imp;

----------------------------------------------
-- Instruction Register
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

entity instruction_reg is 
  port(
    clk: in std_logic;
	 rst: in std_logic;
	 pstate: in controlstates;
	 cmd: in instruction;
	 IR: out instruction
  );
end instruction_reg;

architecture imp of instruction_reg is
  signal IRreg: instruction; --! registrador da instruç~ao recuperada
begin
  -- sa´idas registrada
  IR<= IRreg;
  -- busca da instrucao e registro da mesma
  process(clk,rst,cmd)
  begin
    if (rst='1') then
	   IRreg<= (others=>'0');
    elsif (rising_edge(clk)) then
	   if (pstate=busca) then
	     IRreg<= cmd;
		end if;
	 end if;
  end process;  
end imp;

----------------------------------------------
-- Pilha de m´aquina
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

entity stackreg is
  port(
    clk: in std_logic;
    rst: in std_logic;
    pstate: in controlstates;
    stack_new: in unsigned(data_size-1 downto 0);
    stack_out: out unsigned(data_size-1 downto 0);
    pc_temp_new: in unsigned(data_size-1 downto 0);
    pc_temp: out unsigned(data_size-1 downto 0)
  );
end stackreg;

architecture imp of stackreg is
  signal stack_reg: unsigned(data_size-1 downto 0);
  signal pc_reg: unsigned(data_size-1 downto 0);
begin
  stack_out<= stack_reg;
  pc_temp<= pc_reg;
  -- registrador de stack 
  process(clk,rst)
  begin
    if (rst='1') then
      stack_reg<= (others=>'1');
    elsif rising_edge(clk) then
      if (pstate=atualiza) then
        stack_reg<= stack_new;
      end if;
    end if;
  end process;

  -- PC temp register for RETcode
  process(clk,rst)
  begin
    if (rst='1') then
      pc_reg<= (others=>'0');
    elsif rising_edge(clk) then
      pc_reg<= pc_temp_new;
    end if;
  end process;
end imp;
  
----------------------------------------------
-- Instruction Decoder
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

entity instr_decoder is 
  port(
    -- par^ametros de an´alise
	 pstate: in controlstates; --! estado da execuç~ao 
	 IR: in instruction; --! instruç~ao registrada
    -- par^ametros auxiliares (de outras unidades)
    r1: in reg_word;
    r2: in reg_word;
    last_carry_out: in std_logic; --! ´ultimo carry out gerado pela ULA
    stack_reg: in unsigned(ramsize-1 downto 0);
    nextPC: in unsigned(romsize-1 downto 0);
    pc_temp: in unsigned(ramsize-1 downto 0);
    ULAout: in reg_word; 
    datain: in reg_word;
    -- sinais decodificados
    is_instr_ula: out boolean; --! indica se a instruç~ao ´e associada a ULA
    is_instr_control: out boolean; --! indica se a instruç~ao ´e associada a controle
    is_instr_memory: out boolean; --! indica se a instruç~ao ´e associada a mem´oria ou I/O
    is_instr_misc: out boolean; --! indica se a instruç~ao est´a na categoria miscel^anea
    ula_opcode: out ula_type; --! opcode da operaç~ao com ULA
    memory_opcode: out memory_type; --! opcode da operaç~ao com mem´oria ou I/O
    control_opcode: out control_type; --! opcode da operaç~ao de controle
    reg_update_sel: out reg_sel; --! registrador que deve ser atualizado ao final da operaç~ao
    r1_sel: out reg_sel; --! registrador r1 da operaç~ao
    r2_sel: out reg_sel; --! registrador r2 da operaç~ao
    ULA_A: out reg_word; --! operando A para a ULA
    ULA_B: out reg_word; --! oparando B para a ULA
    carry_in: out std_logic; --! sinal de carry in para a ULA
    we: out std_logic; --! habilitaç~ao de escrita para RAM
	 waddr: out std_logic_vector(ramsize-1 downto 0); --! endereço de escrita da RAM
	 raddr: out std_logic_vector(ramsize-1 downto 0); --! endereço de leitura da RAM
    dataout: out std_logic_vector(data_size-1 downto 0); --! dados de escrita da RAM
    valor: out std_logic_vector(data_size-1 downto 0); --! valor num´erico associado a operaç~ao
    jmpvalor: out unsigned(romsize-1 downto 0); --! endereço de salto
    stack_new: out unsigned(ramsize-1 downto 0);
    pc_temp_new: out unsigned(ramsize-1 downto 0)
  );
end instr_decoder;

architecture imp of instr_decoder is
  -- operandos
  signal r1_instr: reg_sel; --! operando r1 retirado da instruç~ao
  signal r2_instr: reg_sel; --! operando r2 retirado da instruç~ao
  -- decodificacao
  signal instr_group: instr_type; --! grupo de instruç~ao decodificada
  signal local_ula_opcode: ula_type; --! opcode da operaç~ao com ULA
  signal local_memory_opcode: memory_type; --! opcode da operaç~ao com mem´oria ou I/O
  signal local_control_opcode: control_type;
  signal local_valor: std_logic_vector(data_size-1 downto 0); --! valor num´erico associado a operaç~ao
  -- sinais de apoio
  signal local_pc_temp_new: unsigned(data_size-1 downto 0);
  
  -- parcela da instrucao
  constant geral_left: integer:= instruction'left;
  constant geral_right: integer:= geral_left-instr_type'length+1;
  constant sub_left: integer:= geral_right-1;
  constant sub_right: integer:= sub_left-instr_subtype'length+1;
  constant r1_left: integer:= sub_right-1;
  constant r1_right: integer:= r1_left-reg_subtype'length+1;
  constant r2_left: integer:= r1_right-1;
  constant r2_right: integer:= r2_left-reg_subtype'length+1;
  constant valop_left: integer:= r2_right-1;
  constant valop_right: integer:= 0;
begin
  -- partes da instruçao (testar com alias depois)
  instr_group<= IR(geral_left downto geral_right);
  -- operandos
  r1_instr<= unsigned(IR(r1_left downto r1_right));
  r2_instr<= unsigned(IR(r2_left downto r2_right));
  local_valor<= IR(valop_left downto valop_right);
  
  -- lança os demais valores para a sa´ida do decoder
  ula_opcode<= local_ula_opcode;
  memory_opcode<= local_memory_opcode;
  control_opcode<= local_control_opcode;
  valor<= local_valor;
  
  -- decodifica a instruçao, gerando sinais de controle adequados
  process(IR,pstate,instr_group,local_ula_opcode,local_memory_opcode,local_control_opcode,r1_instr,
    r2_instr,r1,r2,local_valor,ULAout,last_carry_out,stack_reg,nextPC,datain,pc_temp)
    variable sec_seg_PC: std_logic_vector(romsize-1 downto data_size);
    variable sec_seg: std_logic_vector(data_size-sec_seg_PC'length-1 downto 0);
  begin
    -- VALORES DEFAULT DE DECODIFICAÇ~AO
    jmpvalor<= unsigned(IR(jmpvalor'range));
    is_instr_control<= false;
	 is_instr_ula<= false;
    is_instr_memory<= false;
    is_instr_misc<= false;
	 ULA_A<= (others=>'0');
    ULA_B<= (others=>'0');
	 carry_in<= '0';
	 reg_update_sel<= "000";
	 r1_sel<= "000";
	 r2_sel<= "000";
	 raddr<= (others=>'0');
	 waddr<= (others=>'0');
	 we<= '0';
	 dataout<= r1;
    local_ula_opcode<= IR(sub_left downto sub_right);
    local_memory_opcode<= IR(sub_left downto sub_right);
    local_control_opcode<= IR(sub_left downto sub_right);
    stack_new<= stack_reg;
    pc_temp_new<= (others=>'0');
	 
	 -- altera o default de acordo com a instruçao considerada 
    -- a decodificaç~ao permanece ativa durante os tr^es estados de execuç~ao pertinentes (exceto busca)
	 if (pstate=decodifica or pstate=recupera_stack or pstate=executa or pstate=atualiza) then
      case instr_group is
	     when ulacode =>
          is_instr_ula<= true;
			 case local_ula_opcode is 
			   when andcode|orcode|xorcode|addcode|subcode =>
				  -- r1
				  reg_update_sel<= r1_instr;
				  -- r2
				  r1_sel<= r2_instr;
				  -- demais parametros ULA
				  ULA_A<= r1;
				  ULA_B<= local_valor;
				when notcode =>
              -- r1
              r1_sel<= r1_instr;
				  -- r1
				  reg_update_sel<= r1_instr;
				  -- demais parametros ULA
				  ULA_A<= r1;
				when addccode|subccode =>
				  -- r1
				  reg_update_sel<= r1_instr;
				  -- r2
				  r1_sel<= r2_instr;
				  ULA_A<= r1;
				  ULA_B<= local_valor;
				  carry_in<= last_carry_out;
				when others=>
			 end case;
		  when memorycode=>
          is_instr_memory<= true;
			 case local_memory_opcode is
			   when ldcode =>
				  -- r1
				  reg_update_sel<= r1_instr;
				  -- r2
				  r2_sel<= r2_instr;
				  -- aciona a ULA para determinar o endereço final
				  ULA_A<= r2;
				  ULA_B<= local_valor;
				  local_ula_opcode<= addcode;
				  -- joga o resultado da ULA para a memoria RAM
				  raddr<= ULAout;
				when stcode =>
				  -- r1
				  r1_sel<= r1_instr;
				  -- r2
				  r2_sel<= r2_instr;
				  -- aciona a ULA para determinar o endereço final
				  ULA_A<= r2;
				  ULA_B<= local_valor;
				  local_ula_opcode<= addcode;
				  -- joga o resultado da ULA para a memoria RAM
				  waddr<= ULAout;
				  if (pstate=decodifica or pstate=executa) then
				    we<= '1';
				  end if;
				when incode =>
				  -- r1
				  reg_update_sel<= r1_instr;
				when outcode =>
				  -- r1
				  r1_sel <= r1_instr;
				when others =>
			 end case;
        when controlcode=>
          is_instr_control<= true;
          case local_control_opcode is
            when callcode=>
              -- armazena na mem´oria RAM, na posiç~ao indicada pelo stackreg
              -- o endereço correspondente a posiç~ao de retorno (PC+1)
              -- isso demanda dois estados da m´aquina
              case pstate is
                when decodifica=>
                  waddr<= std_logic_vector(stack_reg);
                  dataout<= std_logic_vector(nextPC(data_size-1 downto 0));
                  we<= '1';
                when executa=>
                  waddr<= std_logic_vector(stack_reg-1);
                  sec_seg_PC:= std_logic_vector(nextPC(romsize-1 downto data_size));
                  sec_seg:= (others=>'0');
                  dataout<= sec_seg & sec_seg_PC;
                  we<= '1';
                  stack_new <= unsigned(ULAout);
                when others=>
                  stack_new <= unsigned(ULAout);
              end case;
              -- aciona a ULA para subtrair o stack pelo tamanho necess´ario para armazenar um endereço
              -- se a RAM for maior que 256 posiç~oes, a´i teremos que alterar esse mecanismo
              ULA_A<= reg_word(stack_reg);
              ULA_B<= b"0000_0010"; -- subtrai dois visto que cada endereço ocupa 2 bytes;
              local_ula_opcode<= subcode;
            when retcode=>
              -- recupera o endereço de retorno da RAM (parte mais significativa)
              case pstate is
                when decodifica =>
                  raddr<= std_logic_vector(stack_reg+1);
                when recupera_stack =>
                  report "Entrou aqui..." severity warning;
                  -- estabelece parte do endereço de retorno
                  pc_temp_new<= unsigned(datain);
                  -- indica recuperaç~ao do pr´oximo segmento do endereço
                  raddr<= std_logic_vector(stack_reg+2);
                when executa => 
                  jmpvalor<= pc_temp(romsize-data_size-1 downto 0) & unsigned(datain);
                when others => 
                  stack_new <= unsigned(ULAout);
              end case;
              -- aciona a ULA para subtrair o stack pelo tamanho necess´ario para armazenar um endereço
              -- se a RAM for maior que 256 posiç~oes, a´i teremos que alterar esse mecanismo
              ULA_A<= reg_word(stack_reg);
              ULA_B<= b"0000_0010"; -- subtrai dois visto que cada endereço ocupa 2 bytes;
              local_ula_opcode<= addcode;
            when others=>
          end case;
		  when others=>
		    is_instr_misc<= true;
	   end case;
	  end if;
  end process;
end imp;
