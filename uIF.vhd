----------------------------------------------
--! @file uIF.vhd
--! @brief Core do uIF
--! @date abr-2024
--! @version 0.1
--! @author Ricardo Balbinot
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

--! @brief Núcleo do uIF
entity uIF is
  generic(
    debug: boolean:= false --! indica se eh para ativar o debug
  );
  port(
    -- sinais gerais
	 clk: in std_logic; --! sinal de clock
	 rst: in std_logic; --! sinal de reset
    -- interface com RAM
	 datain: in std_logic_vector(data_size-1 downto 0); --! entrada de dados da RAM
	 dataout: out std_logic_vector(data_size-1 downto 0); --! saida de dados para RAM
	 we: out std_logic; --! habilitacao de escrita para RAM
	 waddr: out std_logic_vector(ramsize-1 downto 0);
	 raddr: out std_logic_vector(ramsize-1 downto 0);
	 -- interface com ROM
	 progdata: in instruction;
	 progaddr: out std_logic_vector(romsize-1 downto 0);
	 -- interface I/O
	 isignals: in std_logic_vector(io_size-1 downto 0);
	 osignals: out std_logic_vector(io_size-1 downto 0)
  );
end uIF;

architecture imp of uIF is
  -- sinais de controle
  -- gerais
  signal r1,r2: reg_word;
  signal r1_sel,r2_sel: reg_sel;
  -- de status
  signal cflag_i: std_logic;
  signal cflag_o: std_logic;
  signal zflag_i: std_logic;
  signal zflag_o: std_logic;
  signal sflag_i: std_logic;
  signal sflag_o: std_logic;
  -- program counter
  signal PC: unsigned(romsize-1 downto 0);
  signal nextPC: unsigned(romsize-1 downto 0);
  -- de instruçao
  signal IR: instruction;
  -- de resultado da ULA
  signal ULAreg: reg_word;
  signal carry_in: std_logic;
  signal carry_out: std_logic;
  signal zero_out: std_logic;
  signal signal_out: std_logic;
  -- bloco lido do buffer de entrada do m´odulo de I/O
  signal inputblock: reg_word;
  -- da memoria RAM ou I/O
  signal MEMreg: reg_word;
  
  -- sinais de controle
  signal reg_update: boolean;
  signal reg_update_data: reg_word;
  signal reg_update_sel: reg_sel;

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

  -- decodificacao
  --signal instr_group: instr_type;
  --alias ula_opcode is IR(sub_left downto sub_right);
  signal ula_opcode: ula_type;
  signal memory_opcode: memory_type;
  signal control_opcode: control_type;
  signal is_instr_ula: boolean;
  signal is_instr_control: boolean;
  signal is_instr_memory: boolean;
  signal is_instr_misc: boolean;
  -- operandos
  signal r1_instr: reg_sel;
  signal r2_instr: reg_sel;
  signal valor: std_logic_vector(data_size-1 downto 0);
  signal jmpvalor: unsigned(romsize-1 downto 0);
  -- operandos da ULA
  signal ULAout: reg_word;
  signal ULA_A, ULA_B: reg_word;
  
  -- pilha de m´aquina
  signal stack_reg: unsigned(ramsize-1 downto 0);
  signal stack_new: unsigned(ramsize-1 downto 0);
  signal pc_temp_new: unsigned(ramsize-1 downto 0);
  signal pc_temp: unsigned(ramsize-1 downto 0);
  

  signal pstate,nstate: controlstates;
begin
  -- DATAPATH
  
  -- Program Counter
  pcunit: entity work.pgrCounter(imp) port map(
    clk => clk,
	 rst => rst,
	 addr => PC,
    nextaddr => nextPC,
	 pstate => pstate,
    jump => is_instr_control,
    cflag => cflag_i,
    zflag => zflag_i,
    condition => control_opcode,
    jmpaddr => jmpvalor
  );
	 
  -- ULA
  ula: entity work.ula(imp) port map(
    opcode => ula_opcode, 
	 Adata => ULA_A,
    Bdata => ULA_B,
	 Ydata => ULAout,
	 cin => carry_in,
	 cout => carry_out,
	 zflag => zero_out,
    sflag => signal_out
  ); 
  
  zflag_o<= zero_out;
  cflag_o<= carry_out;
  sflag_o<= signal_out;
  
  -- Registrador de saida da ULA
  ula_reg: entity work.ula_register(imp) port map(
    clk => clk,
	 rst => rst,
	 pstate => pstate,
	 update => is_instr_ula,
	 opcode => ula_opcode,
	 ula_in => ULAout,
	 carry_in => cflag_o,
	 zflag_in => zflag_o,
    sflag_in=> sflag_o,
	 ula_out => ULAreg,
	 carry_out => cflag_i,
	 zflag_out => zflag_i,
    sflag_out => sflag_i
  );
  
  -- GPR
  gprunit: entity work.gpr(imp) port map(
    clk=> clk,
	 rst=> rst,
	 pstate=> pstate,
	 datai=> reg_update_data,
	 in_sel=> reg_update_sel,
	 in_update=> reg_update,
	 r1_sel=> r1_sel,
	 r2_sel=> r2_sel,
	 r1=> r1,
	 r2=> r2
  );
  
  -- Registrador de instruçao
  irunit: entity work.instruction_reg(imp) port map(
    clk=>clk,
	 rst=>rst,
	 pstate=>pstate,
	 cmd=>progdata,
	 IR=>IR
  );
  
  idecoder: entity work.instr_decoder(imp) port map(
    pstate => pstate,
    IR=> IR,
    r1=> r1,
    r2=> r2,
    last_carry_out=> cflag_i,
    stack_reg=> stack_reg,
    nextPC=> nextPC,
    pc_temp=> pc_temp,
    ULAout=> ULAout,
    datain=> datain,
    is_instr_ula=> is_instr_ula,
    is_instr_control=> is_instr_control,
    is_instr_memory=> is_instr_memory,
    is_instr_misc=> is_instr_misc,
    ula_opcode=> ula_opcode,
    memory_opcode=> memory_opcode,
    control_opcode=> control_opcode,
    reg_update_sel=> reg_update_sel,
    r1_sel=> r1_sel,
    r2_sel=> r2_sel,
    ULA_A=> ULA_A,
    ULA_B=> ULA_B,
    carry_in=> carry_in,
    we=> we,
    waddr=> waddr,
    raddr=> raddr,
    dataout=> dataout,
    valor=> valor,
    jmpvalor=> jmpvalor,
    stack_new=> stack_new,
    pc_temp_new=> pc_temp_new
  );
  

  -- sinais globais
  progaddr <= std_logic_vector(PC);
  
  -- m´odulo I/O
  iounit: entity work.iomodule(imp) port map(
    clk=> clk,
    rst=> rst,
    pstate=> pstate,
    is_instr_memory=> is_instr_memory,
    opcode=> memory_opcode,
    ioblock=> valor,
    isignals=> isignals,
    osignals=> osignals,
    writesignal=> r1,
    readsignal=> inputblock
  );

  -- mux de seleç~ao dos dados para escrita no GPR
  gprmux: entity work.gprmux(imp) port map(
    clk=> clk,
    rst=> rst,
    pstate=> pstate,
    is_instr_memory=> is_instr_memory,
    is_instr_ula=> is_instr_ula,
    opcode=> memory_opcode,
    ula_input=> ULAreg,
    ram_input=> datain,
    io_input=> inputblock,
    reg_update=> reg_update,
    reg_data=> reg_update_data
  );
  
  -- registrador de pilha
  stack: entity work.stackreg(imp) port map(
    clk=> clk,
    rst=> rst,
    pstate=> pstate,
    stack_new=> stack_new,
    stack_out=> stack_reg,
    pc_temp_new=> pc_temp_new,
    pc_temp=> pc_temp
  );
  
  -- CONTROLADOR
  process(clk,rst,nstate)
  begin
    if (rst='1') then
	   pstate <= busca;
	 elsif rising_edge(clk) then
	   pstate<= nstate;
	 end if;
  end process;
  
  process(pstate,is_instr_control,control_opcode)
  begin
    nstate<= pstate;
	 case pstate is
	   when busca=>
		  nstate<= decodifica;
		when decodifica=>
        if ((is_instr_control) and (control_opcode=retcode)) then
          nstate<= recupera_stack;
        else 
	  	    nstate<= executa;
        end if;
      when recupera_stack=>
        nstate<= executa;
		when executa=> 
	  	    nstate<= atualiza;
		when atualiza => 
		  nstate<= busca;
	 end case;
  end process;

end imp;

