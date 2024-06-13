----------------------------------------------
--! @file ula.vhd
--! @brief Unidade logico-aritmetica do uIF
--! @date mai-2024
--! @version 0.2
--! @author Ricardo Balbinot
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

entity ula is
  port(
    opcode: in std_logic_vector(3 downto 0);
	 Adata: in std_logic_vector(7 downto 0);
	 Bdata: in std_logic_vector(7 downto 0);
	 Ydata: out std_logic_vector(7 downto 0);
	 cin: in std_logic;
	 cout: out std_logic;
	 zflag: out std_logic;
    sflag: out std_logic
  );
end ula;

architecture imp of ula is
  -- soma para std_logic_vector (deixei para o sintetizador definir o método)
  function soma(left,right: in std_logic_vector; cin: in std_logic) return std_logic_vector is
    variable res: unsigned(left'range);
	 variable carry: unsigned(0 downto 0);
  begin
    assert (left'length=right'length) 
	   report "operandos devem possuir mesmo tamanho" 
		severity failure;
	 if (cin='1') then 
	   carry:= "1";
	 else 
	   carry:= "0";
	 end if;
	 res:= unsigned(left)+unsigned(right)+carry;
	 return std_logic_vector(res);
  end;
  -- subtrai para std_logic_vector (deixei para o sintetizador definir o método)
  function subtrai(left,right: in std_logic_vector; cin: in std_logic) return std_logic_vector is
    variable res: unsigned(left'range);
	 variable carry: unsigned(0 downto 0);
  begin
    assert (left'length=right'length) 
	   report "operandos devem possuir mesmo tamanho" 
		severity failure;
	 if (cin='1') then 
	   carry:= "1";
	 else 
	   carry:= "0";
	 end if;
	 res:= unsigned(left)-unsigned(right)-carry;
	 return std_logic_vector(res);
  end;
  -- sinais de apoio
  signal a,b: std_logic_vector(Adata'length downto 0);
begin
  a<= '0' & Adata;
  b<= '0' & Bdata;
  process(opcode,Adata,Bdata,a,b,cin) is
    variable resadd: std_logic_vector(Ydata'length downto 0);
	 variable res: std_logic_vector(Ydata'range);
	 variable comp2: std_logic_vector(Adata'length downto 0);
	 constant zero: std_logic_vector(Ydata'range):= (others=>'0');
  begin
    -- valores default
    zflag<= '0';
    sflag<= '0';
	 cout<= '0';
    -- conforme a instruç~ao
    case opcode is
	   when andcode|andvcode => 
		  res:= Adata and Bdata;
		  Ydata<= res;
		  if res=zero then 
		    zflag<= '1';
		  end if;      
		when orcode|orvcode => 
		  res:= Adata or Bdata;
		  Ydata<= res;
		  if res=zero then 
		    zflag<= '1';
		  end if;
		when xorcode => 
		  res:= Adata xor Bdata;
		  Ydata<= res;
		  if res=zero then 
		    zflag<= '1';
		  end if;
		when notcode => 
		  res:= not(Adata);
		  Ydata<= res;
		  if res=zero then 
		    zflag<= '1';
		  end if;
		when addcode|addvcode => 
		  resadd:= soma(a,b,'0');
		  Ydata <= resadd(Ydata'range);
		  cout <= resadd(resadd'left);
		  if resadd=('0'&zero) then 
		    zflag<= '1';
		  end if;
        if (resadd(Ydata'left))='1' then
          sflag<= '1';
        end if;
		when addccode => 
		  resadd:= soma(a,b,cin);
		  Ydata <= resadd(Ydata'range);
		  cout <= resadd(resadd'left);
		  if resadd=('0'&zero) then 
		    zflag<= '1';
		  end if;
        if (resadd(Ydata'left))='1' then
          sflag<= '1';
        end if;
		when subcode|subvcode => 
		  resadd:= subtrai(a,b,'0');
		  Ydata <= resadd(Ydata'range);
		  cout <= resadd(resadd'left);
		  if resadd=('0'&zero) then 
		    zflag<= '1';
		  end if;
        if (resadd(Ydata'left))='1' then
          sflag<= '1';
        end if;
		when subccode => 
		  resadd:= subtrai(a,b,cin);
		  Ydata <= resadd(Ydata'range);
		  cout <= resadd(resadd'left);
		  if resadd=('0'&zero) then 
		    zflag<= '1';
		  end if;
        if (resadd(Ydata'left))='1' then
          sflag<= '1';
        end if;
      when shlcode=>
        res:= std_logic_vector(shift_left(unsigned(AData),to_integer(unsigned(Bdata))));
        Ydata<= res;
        if res=zero then 
		    zflag<= '1';
		  end if;
        if (res(Ydata'left))='1' then
          sflag<= '1';
        end if;
      when shrcode=>
        res:= std_logic_vector(shift_right(unsigned(AData),to_integer(unsigned(Bdata))));
        Ydata<= res;
        if res=zero then 
		    zflag<= '1';
		  end if;
        if (res(Ydata'left))='1' then
          sflag<= '1';
        end if;
      when rolcode =>
        res:= std_logic_vector(rotate_left(unsigned(AData),to_integer(unsigned(Bdata))));
        Ydata<= res;
        if res=zero then 
		    zflag<= '1';
		  end if;
        if (res(Ydata'left))='1' then
          sflag<= '1';
        end if;
      when rorcode =>
        res:= std_logic_vector(rotate_right(unsigned(AData),to_integer(unsigned(Bdata))));
        Ydata<= res;
        if res=zero then 
		    zflag<= '1';
		  end if;
        if (res(Ydata'left))='1' then
          sflag<= '1';
        end if;
		when others =>
		  Ydata <= (others => '0');
		  cout <= '0';
		  zflag <= '0';
	 end case;
  end process;
end imp;

----------------------------------------------
-- Registrador de saida da ULA
----------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uIFDefs.all;

entity ula_register is
  port(
    clk: in std_logic;
	 rst: in std_logic;
	 pstate: in controlstates;
	 update: in boolean;
	 opcode: in ula_type;
	 ula_in: in reg_word;
	 carry_in: in std_logic;
	 zflag_in: in std_logic;
    sflag_in: in std_logic;
	 ula_out: out reg_word;
	 carry_out: out std_logic;
	 zflag_out: out std_logic;
    sflag_out: out std_logic
	 );
end ula_register;


architecture imp of ula_register is
  signal ULAreg: reg_word;
  signal carry_reg: std_logic;
  signal zflag_reg: std_logic;
begin
  ula_out<= ULAreg;
  carry_out<= carry_reg;
  zflag_out<= zflag_reg;
  -- registrador de saida da ULA
  process(clk,rst)
  begin
    if (rst='1') then
	   ULAreg<= (others=>'0');
		carry_reg<= '0';
		zflag_reg<= '0';
	 elsif rising_edge(clk) then
	   if (pstate=executa) then
		  if (update) then
	       ULAreg<= ula_in;
			 carry_reg<= carry_in; 
			 zflag_reg<= zflag_in;
		  end if;
		end if;
	 end if;
  end process;
end imp;