create or replace package body nester as 
	y varchar2;
procedure p0(c varchar2(100)) is 
	x0 number;
	procedure p1(d integer) is
		x1 number;
	begin
		x0:=1;
		x1 := x0;
		x0 := x1;
		x1 := y;
	end;
begin
	x0:=4;
	a := p1(2);
end p0;
end;
/
