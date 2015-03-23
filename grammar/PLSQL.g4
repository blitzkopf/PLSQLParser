grammar PLSQL;


file
    : ( create_object ( DIVIDE show_errors )? DIVIDE? )+ EOF
    ;
    
show_errors
    : kSHOW kERRORS SEMI?
    ;

create_object
    : create_package
    | create_package_body
    | create_function
    | create_procedure
    ;

parameter_declarations :
        (   LPAREN  parameter_declaration ( COMMA  parameter_declaration )* RPAREN )
    ;

parameter_declaration :
        ID ( IN | ( ( OUT | IN OUT ) NOCOPY? ) )? datatype
        ( ( ASSIGN | DEFAULT ) expression )?
    ;

declare_section :
    ( type_definition SEMI
    | subtype_definition SEMI
    | cursor_definition SEMI
    | item_declaration SEMI
    | function_declaration_or_definition SEMI
    | procedure_declaration_or_definition SEMI
    | pragma SEMI
    )+
    ;

cursor_definition :
        CURSOR ID parameter_declarations? IS select_statement
    ;

item_declaration
    : variable_declaration
    | constant_declaration
    | exception_declaration
    ;

variable_declaration :
        variable_name=ID datatype (  (  NOT NULL )? (  ASSIGN  | DEFAULT ) expression  )?
    ;

constant_declaration :
        constant_name=ID CONSTANT datatype ( NOT NULL )? (   ASSIGN  | DEFAULT  ) expression
    ;

exception_declaration :
        ID EXCEPTION
    ;

type_definition :
        kTYPE ID IS ( record_type_definition | collection_type_definition | ref_cursor_type_definition )
    ;

subtype_definition :
        SUBTYPE ID IS datatype ( NOT NULL )?
    ;
    
record_type_definition :
	RECORD LPAREN record_field_declaration ( COMMA record_field_declaration )* RPAREN
    ;

record_field_declaration :
	ID datatype ( ( NOT NULL )? ( ASSIGN | DEFAULT ) expression )?
    ;

collection_type_definition
	:	varray_type_definition
	|	nested_table_type_definition
	;

varray_type_definition
	:	( VARYING ARRAY? | VARRAY ) LPAREN numeric_literal RPAREN kOF datatype ( NOT NULL )?
	;

nested_table_type_definition
	:	TABLE kOF datatype ( NOT NULL )? ( INDEX BY associative_index_type )?
	;

associative_index_type
	:	datatype
	;

ref_cursor_type_definition
	:	REF CURSOR ( RETURN datatype )?
	;

datatype
    : ( REF )? ID ( DOT ID )? ( LPAREN numeric_literal ( COMMA numeric_literal )* RPAREN | PERCENT ( kTYPE | ROWTYPE ) )?
    ;

function_declaration_or_definition :
        FUNCTION function_name=ID parameter_declarations? RETURN datatype
        ( DETERMINISTIC | PIPELINED | PARALLEL_ENABLE | RESULT_CACHE )*
        ( ( IS | AS ) declare_section? body )?
	;

procedure_declaration_or_definition :
        PROCEDURE procedure_name=ID parameter_declarations?
        ( ( IS | AS ) declare_section? body )?
    ;
	
body 	:	
	BEGIN statement SEMI ( statement SEMI | pragma SEMI )*
	( EXCEPTION exception_handler+ )? END ID?
	;

exception_handler
	:	WHEN ( qual_id ( OR qual_id )* | OTHERS )
		THEN ( statement SEMI )+
	;
	
statement :
    label*
    ( assign_statement
	| call_statement
    | case_statement
    | close_statement
    | continue_statement
    | basic_loop_statement
    | execute_immediate_statement
    | exit_statement
    | fetch_statement
    | for_loop_statement
    | forall_statement
    | goto_statement
    | if_statement
    | null_statement
    | open_statement
    | plsql_block
    | raise_statement
    | return_statement
    | sql_statement
    | while_loop_statement
	
    )
    ;

lvalue
    : call ( DOT call )*
    ;

assign_statement
    : lvalue  ASSIGN expression 
    ;

call_statement
	:  ( prefix+=call DOT )* element=call   ( LPAREN parameter ( DOT parameter )* RPAREN )?
	;
	
call
    : COLON? element=ID ( LPAREN ( parameter ( COMMA parameter )* )? RPAREN )?
    ;

basic_loop_statement :
        LOOP ( statement SEMI )+ END LOOP label_name?
    ;

case_statement :
        CASE expression?
        ( WHEN expression THEN ( statement SEMI )+ )+
        ( ELSE statement /*SEMI*/ )?
        END CASE label_name?
    ;
case_expression :
        CASE expression?
        ( WHEN expression THEN  expression   )+
        ( ELSE expression  )?
        END 
    ;

	
close_statement :
        CLOSE ID ( DOT ID )?
    ;

continue_statement :
        CONTINUE ( lbl=ID )? ( WHEN expression )?
    ;

execute_immediate_statement :
        EXECUTE IMMEDIATE expression (
        ( into_clause | bulk_collect_into_clause) using_clause?
        | using_clause dynamic_returning_clause?
        | dynamic_returning_clause
        )?
    ;

exit_statement :
        EXIT ( lbl=ID )? ( WHEN expression )?
    ;

fetch_statement :
        FETCH qual_id ( into_clause | bulk_collect_into_clause ( LIMIT numeric_expression )? )
    ;
    
into_clause :
        INTO lvalue ( COMMA lvalue )*
    ;
    
bulk_collect_into_clause :
        BULK COLLECT INTO lvalue ( COMMA lvalue )*
    ;

using_clause :
        USING param_modifiers? expression ( COMMA param_modifiers? expression )*
    ;

param_modifiers
	: IN OUT? | OUT
	;

dynamic_returning_clause :
        ( RETURNING | RETURN ) ( into_clause | bulk_collect_into_clause )
    ;

for_loop_statement :
        FOR ID IN ( ~(LOOP) )+ LOOP ( statement SEMI )+ END LOOP label_name?
    ;

forall_statement :
        FORALL ID IN bounds_clause sql_statement ( kSAVE kEXCEPTIONS )?
    ; 

bounds_clause 
    : numeric_expression DOUBLEDOT numeric_expression
    | kINDICES kOF atom ( BETWEEN numeric_expression AND numeric_expression )?
    | kVALUES kOF atom
    ;

goto_statement :
        GOTO label_name
    ;

if_statement :
        IF expression THEN ( statement SEMI )+
        ( ELSIF expression THEN ( statement SEMI )+ )*
        ( ELSE ( statement SEMI )+ )?
        END IF
    ;

null_statement :
        NULL
    ;

open_statement :
        OPEN ID ( DOT ID )* call_args? ( FOR select_statement )?
    ;

pragma :
        PRAGMA swallow_to_semi
    ;

raise_statement :
        RAISE ( ID ( DOT ID )* )?
    ;

return_statement :
        RETURN expression?
    ;

plsql_block :
        ( DECLARE declare_section )? body
    ;

label :
        LLABEL label RLABEL
    ;

qual_id :
	COLON? ID ( DOT COLON? ID )*
    ;

sql_statement
    : commit_statement
    | delete_statement
    | insert_statement
    | lock_table_statement
    | rollback_statement
    | savepoint_statement
    | select_statement
    | set_transaction_statement
    | update_statement
    ;

commit_statement :
        COMMIT swallow_to_semi?
    ;

delete_statement :
        DELETE swallow_to_semi
    ;

insert_statement :
        INSERT swallow_to_semi
    ;

lock_table_statement :
        LOCK TABLE swallow_to_semi
    ;

rollback_statement :
        ROLLBACK swallow_to_semi?
    ;

savepoint_statement :
        SAVEPOINT ID
    ;

select_statement :
		//SELECT swallow_to_semi
		subquery_factoring_clause?  subquery /*for_update_clause?*/
    ;
subquery :
	 ( query_block 
		/*|  subquery ( UNION ALL? | INTERSECT | MINUS ) subquery*/
		| LPAREN subquery RPAREN 
	) /*order_by_clause?*/
	;

query_block :
	SELECT /*hint?*/ ( DISTINCT | UNIQUE | ALL )? select_list
	FROM from_element ( COMMA from_element )*
	where_clause? /* hirarchial_query_clause? group_by_clause? */
	/*( HAVING condition )?*/ /*model_clause?*/
	;

from_element :
	 table_reference 
	 | join_clause 
	 | LPAREN join_clause RPAREN 
	;

subquery_factoring_clause :
	WITH query_name=id AS LPAREN subquery RPAREN ( COMMA query_name=id AS LPAREN subquery RPAREN )*
	;

select_list :
	ASTERISK
	| select_element ( COMMA select_element )*
	;
	
select_element:
	id ( DOT id )? DOT ASTERISK
	| expression ( AS? id )?
	;

table_reference:
	( ONLY LPAREN query_table_expression RPAREN 
		| query_table_expression /*( pivot_clause | unpivot_clause )?*/
	)  /*flashback_query_clause? */ (t_alias=id)?
	;

query_table_expression:
	/* query_name
	|*/ ( schema=id DOT)?  table=id ( AT dblink=id  /*|partition_extension_clause */ )? /*sample_clause?*/
	| LPAREN subquery /*subquery_restriction_clause?*/ RPAREN
	/*| table_collection_expression*/
	;

join_clause:
	table_reference ( inner_cross_join_clause |outer_join_clause)*
	;

inner_cross_join_clause:
	INNER? JOIN table_reference ( ON condition | USING LPAREN columns+=id ( COMMA columns+=id)* )
	| ( CROSS | NATURAL INNER? ) JOIN table_reference
	;
	
outer_join_clause:
	/* query_partition_clause? */ ( outer_join_type  | NATURAL outer_join_type ) JOIN 
		table_reference  /* query_partition_clause */ 
		( ON condition | USING LPAREN columns+=id ( COMMA columns+=id)* )
	;

outer_join_type:
	( FULL | LEFT | RIGHT ) OUTER?
	;
	

where_clause:
	WHERE condition
	;

condition: 
	expression
	;
	
set_transaction_statement :
        SET TRANSACTION swallow_to_semi
    ;

update_statement :
        UPDATE swallow_to_semi
    ;

swallow_to_semi :
        ~( SEMI )+
    ;

while_loop_statement :
        WHILE expression LOOP ( statement SEMI )+ END LOOP label_name?
    ;

match_parens
    : ( ~( RPAREN | LPAREN | SEMI | AS | IS | IN | OUT ) )* //options {greedy=false;} : 
    | RPAREN match_parens LPAREN
    ;

label_name:	ID;
expression:
    atom
    | expression OR expression
    | expression AND expression
    | NOT expression
    | expression (EQ | NOT_EQ | LTH | LEQ | GTH | GEQ ) expression
    | expression IS NOT? NULL
    | expression NOT? LIKE expression
    | expression NOT? BETWEEN expression AND expression
    | expression NOT? IN LPAREN expression ( COMMA expression )* RPAREN 
	| expression '||' expression
//    | expression 
    | numeric_expression
	| case_expression
    ;

numeric_expression
    : numeric_atom
    | numeric_expression ( '-' | '+' ) numeric_expression
    | numeric_expression ( '*' | '/' | kMOD )  numeric_expression
    | ( '-' | '+' ) numeric_expression
	| atom ( EXPONENT atom )?
    ;

/*expression
    : or_expr
    ;

or_expr
    : and_expr ( OR and_expr )*
    ;

and_expr
    : not_expr ( AND not_expr )*
    ;

not_expr
    : NOT? compare_expr
    ;

compare_expr
    : is_null_expr ( ( EQ | NOT_EQ | LTH | LEQ | GTH | GEQ ) is_null_expr )?
    ;

is_null_expr
    : like_expr ( IS NOT? NULL)?
    ;

like_expr
    : between_expr ( NOT? LIKE between_expr )?
    ;

between_expr
    : in_expr ( NOT? BETWEEN in_expr AND in_expr )?
    ;

in_expr
    : add_expr ( NOT? IN LPAREN add_expr ( COMMA add_expr )* RPAREN )?
    ;



add_expr
    : mul_expr ( ( MINUS | PLUS | DOUBLEVERTBAR ) mul_expr )*
    ;

mul_expr
    : unary_sign_expr ( ( ASTERISK | DIVIDE | kMOD ) unary_sign_expr )*
    ;

unary_sign_expr
    : ( MINUS | PLUS )? exponent_expr
    ;

exponent_expr
    : atom ( EXPONENT atom )?
    ;
*/
atom
    : variable_or_function_call ( PERCENT attribute )?
    | SQL PERCENT attribute
    | string_literal
    | numeric_atom
    | boolean_atom
    | NULL
    | LPAREN expression RPAREN
    ;
    
variable_or_function_call
    : (prefix+=call DOT)* element=call  
//	| call ( DOT call )* call_args
    ;

attribute
    : BULK_ROWCOUNT LPAREN expression RPAREN
    | kFOUND
    | ISOPEN
    | NOTFOUND
    | kROWCOUNT
    ;

call_args
    : LPAREN ( parameter ( COMMA parameter )* )? RPAREN
    ;

boolean_atom
    : boolean_literal
    | collection_exists
    | conditional_predicate
    ;

numeric_atom
    : numeric_literal
    ;

numeric_literal
    : INTEGER
    | REAL_NUMBER
    ;

boolean_literal
    : TRUE
    | FALSE
    ;

string_literal
    : QUOTED_STRING
    ;

collection_exists
    : ID DOT EXISTS LPAREN expression RPAREN
    ;

conditional_predicate
    : INSERTING
    | UPDATING ( LPAREN QUOTED_STRING RPAREN )?
    | DELETING
    ;

parameter
    : ( ID ARROW )? expression
    ;

index
    : expression
    ;

create_package :
        CREATE ( OR kREPLACE )? PACKAGE ( schema_name=ID DOT )? package_name=ID
        ( invoker_rights_clause )?
        ( IS | AS ) ( declare_section )? END ( ID )? SEMI
    ;

create_package_body :
        CREATE ( OR kREPLACE )? PACKAGE BODY  (schema_name=ID DOT)?  package_name=ID
        ( IS | AS ) ( declare_section )?
        ( initialize_section=body | END ( package_name2=ID )? )
        SEMI
    ;

create_procedure :
        CREATE ( OR kREPLACE )? PROCEDURE ( schema_name=ID DOT )? procedure_name=ID
        ( LPAREN parameter_declaration ( COMMA parameter_declaration )* RPAREN )?
        invoker_rights_clause?
        ( IS | AS )
        ( declare_section? body
        | call_spec
        | EXTERNAL
        ) SEMI
    ;

create_function :
        CREATE ( OR kREPLACE )? FUNCTION ( schema_name=ID DOT )? function_name=ID
        ( LPAREN parameter_declaration ( COMMA parameter_declaration )* RPAREN )?
        RETURN datatype
        invoker_rights_clause?
        ( IS | AS )
        ( declare_section? body
        | call_spec
        | EXTERNAL
        ) SEMI
    ;

invoker_rights_clause :
        AUTHID ( CURRENT_USER | DEFINER )
    ;

call_spec
    : LANGUAGE swallow_to_semi
    ;

id: ID;

kERRORS : {_input.LT(1).getText().length() >= 3 && "errors".startsWith(_input.LT(1).getText().toLowerCase())}? ID;
kEXCEPTIONS : {_input.LT(1).getText().equalsIgnoreCase("exceptions")}? ID;
kFOUND : {_input.LT(1).getText().equalsIgnoreCase("found")}? ID;
kINDICES : {_input.LT(1).getText().equalsIgnoreCase("indices")}? ID;
kMOD : {_input.LT(1).getText().equalsIgnoreCase("mod")}? ID;
kNAME : {_input.LT(1).getText().equalsIgnoreCase("name")}? ID;
kOF : {_input.LT(1).getText().equalsIgnoreCase("of")}? ID;
kREPLACE : {_input.LT(1).getText().equalsIgnoreCase("replace")}? ID;
kROWCOUNT : {_input.LT(1).getText().equalsIgnoreCase("rowcount")}? ID;
kSAVE : {_input.LT(1).getText().equalsIgnoreCase("save")}? ID;
kSHOW : {_input.LT(1).getText().equalsIgnoreCase("show")}? ID;
kTYPE : {_input.LT(1).getText().equalsIgnoreCase("type")}? ID;
kVALUES : {_input.LT(1).getText().equalsIgnoreCase("values")}? ID;

ALL : A L L ;
AND :    A N D ;
ARRAY :  A R R A Y ;
AS : A S ;
AT : A T ;
AUTHID: A U T H I D ;
BETWEEN : B E T W E E N ;
BODY    :   B O D Y ;
BULK: B U L K ;
BULK_ROWCOUNT: B U L K '_' R O W C O U N T ;
BY  :   B Y;
CASE: C A S E;
CREATE: C R E A T E;
CROSS: C R O S S;
COLLECT:    C O L L E C T ;
COMMIT  :   C O M M I T;
CURRENT_USER: C U R R E N T '_' U S E R;
DEFAULT : D E F A U L T ;
DEFINER: D E F I N E R;
DELETE  :   D E L E T E;
DISTINCT : D I S T I N C T ;
ELSE : E L S E ;
ELSIF   :   E L S I F ;
EXTERNAL:   E X T E R N A L;
FALSE   :   F A L S E ;
FETCH   :   F E T C H ;
FOR : F O R  ;
FORALL : F O R A L L  ;
FROM: F R O M ;
FULL: F U L L ;
GOTO    :   G O T O ;
IF  :   I F ;
IN : I N  ;
INDEX : I N D E X  ;
INNER  :   I N N E R;
INSERT  :   I N S E R T ;
INTERSECT: I N T E R S E C T ;
INTO    :   I N T O ;
IS : I S ;
JOIN: J O I N ;
LANGUAGE:   L A N G U A G E ;
LEFT: L E F T ;
LIKE : L I K E  ;
LIMIT : L I M I T  ;
LOCK    :   L O C K ;
NATURAL : N A T U R A L ;
NOT : N O T  ;
NOTFOUND:   N O T F O U N D ;
NULL : N U L L  ;
ONLY  : O N L Y ;
OPEN    :   O P E N ;
ON : O N  ;
OR : O R  ;
OUTER: O U T E R ;
PACKAGE: P A C K A G E;
RAISE   :   R A I S E ;
RIGHT : R I G H T ;
ROLLBACK:   R O L L B A C K ;
SAVEPOINT   :   S A V E P O I N T ;
SELECT  :   S E L E C T ;
SET :   S E T ;
SQL :   S Q L ;
TABLE   :   T A B L E ;
TRANSACTION :   T R A N S A C T I O N ;
TRUE    :   T R U E ;
THEN : T H E N  ;
UNION: U N I O N;
UNIQUE: U N I Q U E;
UPDATE  :   U P D A T E ;
WHERE   :   W H E R E ;
WHILE   :   W H I L E ;
WITH	: 	W I T H ;

INSERTING
    :   I N S E R T I N G ;
UPDATING:   U P D A T I N G ;
DELETING:   D E L E T I N G ;
ISOPEN  :   I S O P E N ;
EXISTS  :   E X I S T S ;

BEGIN   :   B E G I N   ;
CLOSE   :   C L O S E ;
CONSTANT    :   C O N S T A N T   ;
CONTINUE:   C O N T I N U E ;
CURSOR  :   C U R S O R     ;
DECLARE :   D E C L A R E    ;
DETERMINISTIC   : D E T E R M I N I S T I C    ;
END :   E N D ;
EXCEPTION   :   E X C E P T I O N  ;
EXECUTE :   E X E C U T E ;
EXIT    :   E X I T ;
FUNCTION    :   F U N C T I O N   ;
IMMEDIATE   :   I M M E D I A T E ;
LOOP    :   L O O P ;
NOCOPY  :   N O C O P Y     ;
OTHERS  :   O T H E R S     ;
OUT :   O U T    ;
PARALLEL_ENABLE :   P A R A L L E L '_' E N A B L E ;
PIPELINED   :   P I P E L I N E D  ;
PRAGMA  :   P R A G M A     ;
PROCEDURE   :   P R O C E D U R E  ;
RECORD  :   R E C O R D     ;
REF :   R E F    ;
RESULT_CACHE    :   R E S U L T '_' C A C H E   ;
RETURN  :   R E T U R N     ;
RETURNING   :   R E T U R N I N G  ;
ROWTYPE :   R O W T Y P E    ;
SUBTYPE :   S U B T Y P E    ;
USING:  U S I N G  ;
VARRAY  :   V A R R A Y     ;
VARYING :   V A R Y I N G    ;
WHEN    :   W H E N   ;

QUOTED_STRING
	:	( 'n' )? '\'' ( '\'\'' | ~('\'') )* '\''
	;

ID
	:	( 'a' .. 'z' | 'A' .. 'Z')
		( 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '$' | '#' )*
	|	DOUBLEQUOTED_STRING
	;
SEMI
	:	';'
	;
COLON
	:	':'
	;
DOUBLEDOT
	:	POINT POINT
	;
DOT
	:	POINT
	;
fragment
POINT
	:	'.'
	;
COMMA
	:	','
	;
EXPONENT
	:	'**'
	;
ASTERISK
	:	'*'
	;
AT_SIGN
	:	'@'
	;
RPAREN
	:	')'
	;
LPAREN
	:	'('
	;
RBRACK
	:	']'
	;
LBRACK
	:	'['
	;
PLUS
	:	'+'
	;
MINUS
	:	'-'
	;
DIVIDE
	:	'/'
	;
EQ
	:	'='
	;
PERCENT
	:	'%'
	;
LLABEL
	:	'<<'
	;
RLABEL
	:	'>>'
	;
ASSIGN
	:	':='
	;
ARROW
	:	'=>'
	;
VERTBAR
	:	'|'
	;
DOUBLEVERTBAR
	:	'||'
	;
NOT_EQ
	:	'<>' | '!=' | '~='| '^='
	;
LTH
	:	'<'
	;
LEQ
	:	'<='
	;
GTH
	:	'>'
	;
GEQ
	:	'>='
	;
INTEGER
    :   NUM
    ;
REAL_NUMBER
	:	NUMBER_VALUE	( 'e' ( PLUS | MINUS )? NUM )?
	;
fragment
NUMBER_VALUE
	:	NUM POINT NUM //{numberDotValid()}?=> NUM POINT NUM?
	|	POINT NUM
	|	NUM
	;
fragment
NUM
	: '0' .. '9' ( '0' .. '9' )*
	;
fragment
DOUBLEQUOTED_STRING
	:	'"' ( ~('"') )* '"'
	;
WS	:	(' '|'\r'|'\t'|'\n') {setChannel(HIDDEN);}
	;
SL_COMMENT
	:	'--' ~('\n'|'\r')* '\r'? '\n' {setChannel(HIDDEN);}
	;
ML_COMMENT
	:	'/*' ( . )*? '*/' {setChannel(HIDDEN);} // options {greedy=false;} :
 	;

/* case insensitive lexer matching */
fragment A:('a'|'A');
fragment B:('b'|'B');
fragment C:('c'|'C');
fragment D:('d'|'D');
fragment E:('e'|'E');
fragment F:('f'|'F');
fragment G:('g'|'G');
fragment H:('h'|'H');
fragment I:('i'|'I');
fragment J:('j'|'J');
fragment K:('k'|'K');
fragment L:('l'|'L');
fragment M:('m'|'M');
fragment N:('n'|'N');
fragment O:('o'|'O');
fragment P:('p'|'P');
fragment Q:('q'|'Q');
fragment R:('r'|'R');
fragment S:('s'|'S');
fragment T:('t'|'T');
fragment U:('u'|'U');
fragment V:('v'|'V');
fragment W:('w'|'W');
fragment X:('x'|'X');
fragment Y:('y'|'Y');
fragment Z:('z'|'Z');
