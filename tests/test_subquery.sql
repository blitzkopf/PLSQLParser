create PACKAGE BODY RECURSIVE_AUDIT AS

  procedure add_audit_objects(p_count number) AS
    v_id number;
    v_owner varchar2(32);
    v_name varchar2(64);
    v_type varchar2(32);
  BEGIN
      select id,owner,name,type 
        into v_id,v_owner,v_name,v_type
      from audit_objects 
      where id in ( 
        select id
        from X
        	where 1 = 1
        order by id 
        );
  END add_audit_objects;
 end;
 /