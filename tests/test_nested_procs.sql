create or replace package body nester as 
	y varchar2;
procedure p0(c varchar2(100)) is 
	x0 number;
	procedure p1(d integer) is
		x1 number;
	begin
		x0:=1;
		x1 := x0;
	end;
begin
	x0:=4;
end p0;
end;
/
