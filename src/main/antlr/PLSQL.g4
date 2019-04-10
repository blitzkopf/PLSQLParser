grammar PLSQL;


file
    : ( create_object ( DIVIDE show_errors )? DIVIDE? )+ EOF
    ;
    
show_errors
    : SHOW ERRORS SEMI?
    ;

create_object
    : create_package
    | create_package_body
    | create_function
    | create_procedure
	| create_view
    ;

parameter_declarations :
        (   LPAREN  parameter_declaration ( COMMA  parameter_declaration )* RPAREN )
    ;

parameter_declaration : 
        param=id ( IN | ( ( OUT | IN OUT ) NOCOPY? ) )? datatype
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
        CURSOR cursor_name=id parameter_declarations? IS select_statement
    ;

item_declaration
    : variable_declaration
    | constant_declaration
    | exception_declaration
    ;

variable_declaration :
        variable_name=id datatype (  (  NOT NULL )? ( ASSIGN  | DEFAULT )? expression  )?
    ;

constant_declaration :
        constant_name=id CONSTANT datatype ( NOT NULL )? ( ASSIGN  | DEFAULT  ) expression
    ;

exception_declaration :
        id EXCEPTION
    ;

type_definition :
        TYPE id IS ( record_type_definition | collection_type_definition | ref_cursor_type_definition )
    ;

subtype_definition :
        SUBTYPE id IS datatype ( NOT NULL )?
    ;
    
record_type_definition :
	RECORD LPAREN record_field_declaration ( COMMA record_field_declaration )* RPAREN
    ;

record_field_declaration :
	id datatype ( ( NOT NULL )? ( ASSIGN | DEFAULT ) expression )?
    ;

collection_type_definition
	:	varray_type_definition
	|	nested_table_type_definition
	;

varray_type_definition
	:	( VARYING ARRAY? | VARRAY ) LPAREN numeric_literal RPAREN OF datatype ( NOT NULL )?
	;

nested_table_type_definition
	:	TABLE OF datatype ( NOT NULL )? ( INDEX BY associative_index_type )?
	;

associative_index_type
	:	datatype
	;

ref_cursor_type_definition
	:	REF CURSOR ( RETURN datatype )?
	;

datatype
    :  ( REF )? elements+=id ( DOT elements+=id )* dblink?( LPAREN numeric_literal ( COMMA numeric_literal )* ( BYTE | CHAR )? RPAREN | PERCENT type=( TYPE | ROWTYPE ) | RAW )?
	| ROWID
    ;

function_declaration_or_definition :
        FUNCTION function_name=id parameter_declarations? RETURN datatype
        ( DETERMINISTIC | PIPELINED | PARALLEL_ENABLE | RESULT_CACHE )*
        ( ( IS | AS ) ( declare_section? body  | call_spec) )?
	;

procedure_declaration_or_definition :
        PROCEDURE procedure_name=id parameter_declarations?
        ( ( IS | AS ) ( declare_section? body | call_spec ) )?
    ;
	
body 	:	
	BEGIN statement SEMI ( statement SEMI | pragma SEMI )*
	( EXCEPTION exception_handler+ )? END id?
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
	| pipe_row_statement
	
    )
    ;

lvalue
    : call ( DOT call )*
    ;

assign_statement
    : lvalue  ASSIGN expression 
    ;

call_statement
	:  elements+=call ( DOT elements+=call )* dblink? ( LPAREN parameter ( COMMA parameter )* RPAREN )?
	;
	
call
    : COLON? name=id ( LPAREN ( parameter ( COMMA parameter )* )? RPAREN )*
    ;

basic_loop_statement :
        LOOP ( statement SEMI )+ END LOOP label_name?
    ;

case_statement :
        CASE expression?
        ( WHEN expression THEN ( statement SEMI )+ )+
        ( ELSE ( statement SEMI )+ )?
        END CASE label_name?
    ;
case_expression :
        CASE expression
        ( WHEN expression THEN  expression   )+
        ( ELSE expression  )?
        END 
	| CASE 
        ( WHEN expression THEN  expression   )+
        ( ELSE expression  )?
        END
    ;
	
close_statement :
        CLOSE id ( DOT id )?
    ;

continue_statement :
        CONTINUE ( lbl=id )? ( WHEN expression )?
    ;

execute_immediate_statement :
        EXECUTE IMMEDIATE expression (
        ( into_clause | bulk_collect_into_clause) using_clause?
        | using_clause dynamic_returning_clause?
        | dynamic_returning_clause
        )?
    ;

exit_statement :
        EXIT ( lbl=id )? ( WHEN expression )?
    ;

fetch_statement :
        FETCH qual_id ( into_clause | bulk_collect_into_clause ( LIMIT expression )? )
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
		FOR variable_name=id IN ( LPAREN select_statement RPAREN | call_statement )  LOOP 
			( statement SEMI )+ END LOOP label_name?
	|	FOR variable_name=id IN REVERSE? expression DOUBLEDOT expression LOOP
			( statement SEMI )+ END LOOP label_name?
    ;

forall_statement :
        FORALL variable_name=id IN bounds_clause ( SAVE EXCEPTIONS )? sql_statement 
    ; 

bounds_clause 
    : expression DOUBLEDOT expression
    | kINDICES OF atom ( BETWEEN expression AND expression )?
    | kVALUES OF atom
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
        OPEN id ( DOT id )* call_args? ( FOR ( select_statement | expression ) using_clause? )?
    ;
/*using_clause :
	USING ( IN | OUT | IN OUT)? parameter ( COMMA? parameter )*
	;
*/
pragma :
        PRAGMA swallow_to_semi
    ;

raise_statement :
        RAISE ( id ( DOT id )* )?
    ;

return_statement :
        RETURN expression?
    ;

plsql_block :
        ( DECLARE declare_section? )? body
    ;

label :
        LLABEL label_id=id RLABEL
    ;
pipe_row_statement:
	PIPE ROW LPAREN expression RPAREN
	;
qual_id :
	COLON? id ( DOT COLON? id )*
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
	| merge_statement
    ;

commit_statement :
        COMMIT swallow_to_semi?
    ;

delete_statement :
        DELETE FROM? ( dml_table_expression_clause  | ONLY LPAREN dml_table_expression_clause RPAREN ) t_alias=id?
		( where_clause | WHERE CURRENT OF id )? returning_clause? error_logging_clause?
    ;

insert_statement :
	//INSERT swallow_to_semi
	INSERT /*hint?*/ ( single_table_insert  /*| multi_table_insert */)
    ;

single_table_insert:
	insert_into_clause ( values_clause ( returning_clause )? | subquery ) /*error_logging_clause? */
	;

insert_into_clause:
	INTO dml_table_expression_clause (t_alias=id)? ( LPAREN (id DOT )? columns+=id ( COMMA (id DOT )?columns+=id )* RPAREN )?
	;
dblink:
	AT_SIGN name=id ( DOT domain+=id )*
	;

dml_table_expression_clause:
	( schema=id DOT )? table=id ( dblink?  /*|partition_extension_clause */ )? # dml_table_def
	| LPAREN subquery subquery_restriction_clause? RPAREN # dml_subquery 
	| table_collection_expression  # dml_collection
	;
	
values_clause:
	VALUES   ( 
		LPAREN ( expr | DEFAULT ) ( COMMA ( expr | DEFAULT ))* RPAREN
		| call_statement // PL/SQL collections and objects.
	)
	;

returning_clause:
	( RETURNING | RETURN ) expr ( COMMA expr )* INTO lvalue ( COMMA lvalue )*
	;
lock_table_statement :
        LOCK TABLE swallow_to_semi
    ;

rollback_statement :
        ROLLBACK swallow_to_semi?
    ;

savepoint_statement :
        SAVEPOINT id
    ;

select_statement :
		//SELECT swallow_to_semi
		subquery_factoring_clause?  subquery ( for_update_clause order_by_clause? ) ?
    ;
subquery :
	query_block order_by_clause?
	|  subquery (( UNION ALL? | INTERSECT | MINUS_SET ) subquery )+ order_by_clause?
	| LPAREN subquery RPAREN order_by_clause?
	;

for_update_clause:
	FOR UPDATE ( OF  for_update_column  ( COMMA for_update_column )* )?  ( NOWAIT | WAIT expr | SKIPl LOCKED )?
	;
for_update_column:
	( (schema=id DOT )? table=id  DOT )? column=id
	;
	
query_block :
	SELECT /*hint?*/ ( DISTINCT | UNIQUE | ALL )? select_list
    ( ( BULK COLLECT )? INTO lvalue (COMMA lvalue)* )? /* Probably should create special select into statement form PL/SQL */
	FROM from_element ( COMMA from_element )*
	where_clause? hirarchial_query_clause? group_by_clause? 
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
	| expr ( AS? id )?
	;

table_reference:
	( ONLY LPAREN query_table_expression RPAREN 
		| query_table_expression ( pivot_clause  | unpivot_clause  )?
	)  /*flashback_query_clause? */ (t_alias=id)?
	;

query_table_expression:
	/* query_name
	|*/ ( schema=id DOT)?  table=id ( dblink?   /*|partition_extension_clause */ )? /*sample_clause?*/ # query_table_def
	| THE? LPAREN subquery_factoring_clause? subquery subquery_restriction_clause? RPAREN # query_subquery
	| table_collection_expression  # query_table_cast
	| LPAREN from_element RPAREN # query_table_paren
	;
subquery_restriction_clause:
	WITH ( READ ONLY | CHECK OPTION ) (CONSTRAINT id)?
	;
	
table_collection_expression:
	TABLE LPAREN expr RPAREN  // should be collection expr 
	| TABLE LPAREN subquery RPAREN  // should be collection expr 
	;

pivot_clause:
		PIVOT XML? LPAREN pivot_element ( COMMA pivot_element )* pivot_for_clause pivot_in_clause  RPAREN
	;
	
pivot_element:
	aggregate_func=id LPAREN expr RPAREN (AS? alias=id)?
	;
	
pivot_for_clause:
	FOR ( colmns += id | LPAREN columns += id ( COMMA columns += id )* RPAREN )
	;
	
pivot_in_clause:
	IN LPAREN ( pivot_in_list | subquery | ANY ( COMMA ANY )* ) RPAREN
	;

pivot_in_list:
	pivot_in_element ( COMMA pivot_in_element )*
	;
pivot_in_element:
	 ( expr
	  | LPAREN expr ( COMMA  expr )*  RPAREN 
	 ) ( AS? alias=id)
	 ;

unpivot_clause:
	UNPIVOT ( ( INCLUDE | EXCLUDE ) NULLS )? 
	LPAREN (
		culumns+=id
		| LPAREN columns+=id ( COMMA columns+=id )* RPAREN
	) pivot_for_clause unpivot_in_clause  RPAREN
	;
unpivot_in_clause:
	IN LPAREN 
		unpivot_in_element ( COMMA unpivot_in_element)*
	RPAREN
	;
unpivot_in_element:
	( columns+=id | LPAREN  columns+=id ( COMMA columns+=id )* RPAREN )
	( AS ( literal | LPAREN literal ( COMMA literal)* RPAREN) )?
;
literal
    : 
    | string_literal
	| date_literal
    | numeric_literal
    | boolean_literal
;

join_clause:
	table_reference ( inner_cross_join_clause |outer_join_clause)*
	;

inner_cross_join_clause:
	INNER? JOIN table_reference ( ON condition | USING LPAREN columns+=id ( COMMA columns+=id)* RPAREN ) 
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

hirarchial_query_clause:
	CONNECT BY NOCYCLE? condition ( START WITH condition )?
	| START WITH condition CONNECT BY NOCYCLE? condition 
	;
group_by_clause:
		GROUP  BY group_by_list (HAVING condition)?
	|	HAVING condition (GROUP  BY group_by_list)?
	;

group_by_list:
	( expr | rollup_cube_clause | grouping_sets_clause)  ( COMMA ( expr | rollup_cube_clause | grouping_sets_clause) )*
	;
rollup_cube_clause:
	( ROLLUP | CUBE ) LPAREN grouping_expression_list RPAREN
	;
grouping_sets_clause:
	GROUPING SETS LPAREN ( rollup_cube_clause | grouping_expression_list ) ( COMMA ( rollup_cube_clause | grouping_expression_list ) )* RPAREN
	;

grouping_expression_list:
	expression_list ( COMMA expression_list )
	;
	
order_by_clause:
	ORDER SIBLINGS? BY order_by_element?  ( COMMA order_by_element )*
	;

order_by_element:
	expr ( ASC | DESC )? ( NULLS FIRST |NULLS LAST )? 
	;

merge_statement:
	MERGE INTO dml_table_expression_clause  t_alias=id? //--( schema=id DOT)?  table=id  t_alias=id? */
	USING  dml_table_expression_clause  u_alias=id?     //--(  ( u_schema=id DOT)?  u_table=id  | subquery ) u_alias=id? 
	ON LPAREN condition RPAREN
	merge_update_clause? merge_insert_clause? error_logging_clause?
	;
	
merge_update_clause:
	WHEN MATCHED THEN UPDATE SET merge_update_column ( COMMA merge_update_column )*
	where_clause? ( DELETE where_clause)?
	;

merge_update_column:
	( prefix=id DOT)? column=id EQ ( expr | DEFAULT ) 
	;


merge_insert_clause:
	WHEN NOT MATCHED THEN INSERT ( LPAREN (id DOT )? columns+=id ( COMMA (id DOT )?columns+=id )* RPAREN )?
	values_clause where_clause?
;

error_logging_clause:
	LOG ERRORS ( INTO (schema=id)? table=id )? ( LPAREN simple_expression )
	( REJECT LIMIT ( INTEGER | UNLIMITED) )?
;

condition: 
	  comparison_condition 
    | floating_point_condition
    // logical_condition + compound_condition
	| LPAREN condition RPAREN 
	| NOT condition   
	| condition ( AND | OR ) condition 
/*    | model_condition
    | multiset_condition */
    | pattern_matching_condition 
    | range_condition 
*/
    | null_condition
/*    | XML_condition
    | compound_condition*/
    | exists_condition
    | in_condition
 /*   | is_of_type_condition
 */   
	| boolean_expression
	| overlaps_condition;
	
boolean_expression:
	// This needs some more thought
	function_expression
	;
comparison_condition:
    simple_comparison_condition
   // | group_comparison_condition
    ;

floating_point_condition:
	expr IS ( NOT )? ( NAN | INFINITE )
	;

simple_comparison_condition:
    expr ( EQ | NOT_EQ | LTH | GTH | LEQ | GEQ ) expr
    | LPAREN expr ( COMMA expr)* RPAREN ( EQ | NOT_EQ ) LPAREN subquery RPAREN 
    ;
/*logical_condition:
	NOT condition
	| condition ( AND | OR ) condition
	;
*/
pattern_matching_condition:
	expr ( NOT )? ( LIKE | LIKEC | LIKE2 | LIKE4 ) expr ( ESCAPE expr )?
	;
null_condition:
	expr IS NOT? NULL
	;
	
range_condition:
	expr ( NOT )? BETWEEN expr AND expr
	;

exists_condition:
	EXISTS LPAREN subquery_factoring_clause? subquery RPAREN
	;

in_condition:
    expr ( NOT )? IN  ( LPAREN ( expression_list | subquery )  RPAREN 
		|  expr  // not in oracle docs, but still allowed syntax
	) 
    | LPAREN expr ( COMMA expr)* RPAREN ( NOT )? IN LPAREN ( expression_list ( COMMA expression_list )* | subquery ) RPAREN 
    ;
overlaps_condition:
	LPAREN expr COMMA expr RPAREN OVERLAPS LPAREN expr COMMA expr RPAREN
	;
expression_list:
    expr (COMMA expr)*
    | LPAREN ( expr (COMMA expr)* )? RPAREN
    ;

expr:
     simple_expression
    // compound_expression
	|LPAREN expr RPAREN
	| ( PLUS | MINUS | PRIOR )  expr
	| expr ( ASTERISK | DIVIDE | PLUS |MINUS | DOUBLEVERTBAR ) expr
    | sql_case_expression    // don't use   PL/SQL  definition of case 
/*    | cursor_expression
    | datetime_expression
    */| function_expression
	| variable_or_function_call
/*    | interval_expression
    | object_access_expression
*/    | scalar_subquery_expression
    | model_expression
/*    | type_constructor_expression
    | variable_expression
*/
    ;

simple_expression:
    ((schema=id DOT )? table=id DOT)? (column=id | ROWID ) ( OUTER_PLUS )?
    | ROWNUM 
    | string_literal
	| date_literal
    | numeric_literal
	| interval_literal
	| boolean_literal // booleans is not really part of Oracle SQL, but need this here until I have a stricter separation between SQL and PL/SQL
    | elements+=id ( DOT elements+=id)* DOT ( CURRVAL | NEXTVAL)
    | NULL
    ;

sql_case_expression :
        CASE expr
        ( WHEN expr THEN  expr   )+
        ( ELSE expr  )?
        END 
	| CASE 
        ( WHEN condition THEN  expr   )+
        ( ELSE expr  )?
      END 
	
    ;
function_expression:
	//((schema=id DOT )? table=id DOT)? function=id LPAREN expr ( COMMA expr)* RPAREN
	elements+=id ( DOT elements+=id)* LPAREN sql_param ( COMMA sql_param)* RPAREN
	| CAST LPAREN ( expr | MULTISET LPAREN subquery RPAREN ) AS id ( DOT id )* ( LPAREN INTEGER ( COMMA INTEGER)? ( BYTE | CHAR)? RPAREN )?  RPAREN
	| extract_function_datetime
	| trim_function
	| object_reference_function ( DOT ( function_expression | id ) )* // Not in oracle docs
	| xmlelement_function
	| first_last_function
	;

sql_param 
    : ( id ARROW )? expr
    ;

object_reference_function:
	xmlagg_function
	
	;
	
extract_function_datetime:
	EXTRACT LPAREN ( YEAR | MONTH | DAY | HOUR | MINUTE | SECOND | TIMEZONE_HOUR | TIMEZONE_MINUTE | TIMEZONE_REGION | TIMEZONE_ABBR ) 
		FROM expr RPAREN
	;
trim_function:
	TRIM LPAREN ( ( LEADING | TRAILING | BOTH )?  expr )? FROM expr  RPAREN
	;

xmlelement_function:
	XMLELEMENT LPAREN  NAME? id ( COMMA xml_attributes_clause )? ( COMMA expr /* value_expr in oracle docs */  ( AS id )?)* RPAREN 
	;

xml_attributes_clause:
	XMLATTRIBUTES LPAREN expr /* value_expr in oracle docs */ ( AS id )? ( COMMA expr /* value_expr in oracle docs */ ( AS  id )? )*
	;
xmlagg_function:
	XMLAGG LPAREN expr order_by_clause? RPAREN 
	;

first_last_function:
	aggr_function+=id LPAREN sql_param  RPAREN KEEP 
	LPAREN DENSE_RANK ( FIRST | LAST ) ORDER BY  order_by_element ( COMMA order_by_element)* RPAREN
	(OVER ( query_partition_clause?))?
	;
scalar_subquery_expression:
	LPAREN subquery RPAREN
	;
	
model_expression:
	//measure_column LBRACKET ( condition | expr ) ( COMMA (  condition | expr ))* RBRACKET
	//| aggregate_function LBRACKET some shit RBRACKET
	/*|*/ analytic_function 
	;

analytic_function:
	( id  LPAREN ( expr ( COMMA expr )*  )? RPAREN
		| aggregate_function 
	)  OVER LPAREN analytic_clause RPAREN
	| listagg_function
	;

analytic_clause:
	query_partition_clause? ( order_by_clause windowing_clause? )?
	;

query_partition_clause:
	PARTITION BY ( expr ( COMMA expr )* | LPAREN expr ( COMMA expr )* RPAREN ) 
	;

windowing_clause:
	( ROWS | RANGE ) ( BETWEEN ( UNBOUNDED PRECEDING | CURRENT ROW | value_expr ( PRECEDING |FOLLOWING)) 
						AND ( UNBOUNDED FOLLOWING | CURRENT ROW | value_expr ( PRECEDING |FOLLOWING) )
					| ( UNBOUNDED PRECEDING | CURRENT ROW | value_expr ( PRECEDING |FOLLOWING))
					)
								
	;
listagg_function:
	LISTAGG LPAREN expr ( COMMA string_literal )? RPAREN WITHIN GROUP LPAREN order_by_clause RPAREN 
		(OVER query_partition_clause)?
	;
	
aggregate_function:
	id LPAREN ( ASTERISK | ( DISTINCT | UNIQUE | ALL )?  expr ) RPAREN 
	;
	
value_expr:
	expression
	;
	
set_transaction_statement :
        SET TRANSACTION swallow_to_semi
    ;

update_statement :
        UPDATE  ( dml_table_expression_clause  | ONLY LPAREN dml_table_expression_clause RPAREN ) t_alias=id?
		update_set_clause ( where_clause | WHERE CURRENT OF id )? returning_clause? error_logging_clause?
    ;
update_set_clause:
	SET ( update_set_element ( COMMA update_set_element )*  | VALUE LPAREN id RPAREN  EQ ( expr | LPAREN subquery RPAREN))
	;
	

update_set_element:
	( 	LPAREN update_column ( COMMA update_column)* RPAREN EQ LPAREN subquery RPAREN 
	  | update_column EQ ( expr | LPAREN subquery RPAREN  | DEFAULT ) 
	)
	;

update_column:
		id ( DOT id )*
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

label_name:	id;
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
	| expression ( MINUS | PLUS ) expression
    | expression ( ASTERISK | DIVIDE | kMOD )  expression
    | ( '-' | '+' ) expression
	| atom ( EXPONENT atom )?
	| case_expression
    ;

/*numeric_expression
    : numeric_atom
    | numeric_expression ( MINUS | PLUS ) numeric_expression
    | numeric_expression ( ASTERISK | DIVIDE | kMOD )  numeric_expression
    | ( '-' | '+' ) numeric_expression
	| atom ( EXPONENT atom )?
    ;
*/
atom
    : variable_or_function_call ( PERCENT attribute )?
	| CAST LPAREN  expression  AS id ( DOT id )* ( LPAREN INTEGER ( COMMA INTEGER)? ( BYTE | CHAR)? RPAREN )?  RPAREN

    | SQL PERCENT attribute
    | string_literal
	| date_literal
    | numeric_atom
    | boolean_atom
    | NULL
    | LPAREN expression RPAREN
    ;
    
variable_or_function_call
    : elements+=call (DOT elements+=call)* (dblink ( LPAREN ( parameter ( COMMA parameter )* )? RPAREN )* )? ( DOT ( NEXTVAL | CURRVAL))? 
//    : (prefix+=call DOT)* element=call  
//	| call ( DOT call )* call_args
	| aggregate_function
	| extract_function_datetime // hope nobody notices this references SQL expr not PL/SQL expressions
    ;

attribute
    : BULK_ROWCOUNT LPAREN expression RPAREN
    | kFOUND
    | ISOPEN
    | NOTFOUND
    | kROWCOUNT
	| BULK_EXCEPTIONS ( LPAREN parameter   RPAREN )? ( DOT call )* 
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
date_literal :
	DATE QUOTED_STRING
	;

interval_literal:
	interval_year_to_month
	| interval_day_to_second
	;
interval_year_to_month:
	INTERVAL QUOTED_STRING ( YEAR | MONTH) (  LPAREN precision=expr RPAREN )? (  TO (YEAR |MONTH ) )?
	;
interval_day_to_second:
	INTERVAL QUOTED_STRING 
	( ( DAY |HOUR | MINUTE ) (  LPAREN leading_precision=expr RPAREN )? 
		| SECOND  (  LPAREN leading_precision=expr   ( COMMA fractional_seconds_precision=expr )? RPAREN)? 
	) 
	( TO ( DAY |HOUR | MINUTE  
		| SECOND  (  LPAREN  fractional_seconds_precision=expr  RPAREN )?
	) )?
	;
	
collection_exists
    : id DOT EXISTS LPAREN expression RPAREN
    ;

conditional_predicate
    : INSERTING
    | UPDATING ( LPAREN QUOTED_STRING RPAREN )?
    | DELETING
    ;

parameter
    : ( id ARROW )? expression
    ;

index
    : expression
    ;

create_package :
        CREATE ( OR REPLACE )? PACKAGE ( schema_name=id DOT )? package_name=id
        ( invoker_rights_clause )?
        ( IS | AS ) ( declare_section )? END ( id )? SEMI
    ;

create_package_body :
        CREATE ( OR REPLACE )? PACKAGE BODY  (schema_name=id DOT)?  package_name=id
        ( IS | AS ) ( declare_section )?
        ( initialize_section=body | END ( package_name2=id )? )
        SEMI
    ;

create_procedure :
        CREATE ( OR REPLACE )? PROCEDURE ( schema_name=id DOT )? procedure_name=id
        ( LPAREN parameter_declaration ( COMMA parameter_declaration )* RPAREN )?
        invoker_rights_clause?
        ( IS | AS )
        ( declare_section? body
        | call_spec
        | EXTERNAL
        ) SEMI
    ;

create_function :
        CREATE ( OR REPLACE )? FUNCTION ( schema_name=id DOT )? function_name=id
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

create_view:
	CREATE ( OR REPLACE )? ( ( NO )? FORCE )? VIEW
	(schema_name=id DOT )? view_name=id ( LPAREN ( alias+=id /*( inline_constraint)*/ /*| out_of_line_constraint*/ ) 
		( COMMA ( alias+=id /*( inline_constraint)*/ /*| out_of_line_constraint*/ ) ) *  RPAREN )?
	AS subquery_factoring_clause? subquery  ( subquery_restriction_clause )? 
	;
	
id:
    ID | ERRORS | EXCEPTIONS | SAVE | SHOW | COUNT | DELETE | TYPE | FIRST | LAST | RIGHT | LEFT | REPLACE | ROW | LANGUAGE 
	| YEAR| MONTH | DAY | HOUR | MINUTE | SECOND | EXTRACT | AT | DATE | TRIM | WAIT | SKIPl | LOCKED | OF | NOWAIT  | NO
	| OPEN | AS | TO | INTERVAL | EXECUTE | CHAR | BYTE | LOG | WITH | ESCAPE | ROWS | REVERSE | SQL | ROWID | PACKAGE | FUNCTION
	| CROSS | RECORD | NAME | PIPE | COMMIT | CURRENT_USER |LIMIT | PRIOR | EXISTS | NOTFOUND | REF |BODY |  TRANSACTION 
	| SUBTYPE | EXTERNAL | FULL | LAST | IF | DENSE_RANK | RAW | READ | VALUE | BULK
    ;
	
id_func:
	id 
	|DISTINCT 
	;

//kERRORS : {_input.LT(1).getText().length() >= 3 && "errors".startsWith(_input.LT(1).getText().toLowerCase())}? ID;
//kEXCEPTIONS : {_input.LT(1).getText().equalsIgnoreCase("exceptions")}? ID;
kFOUND : {_input.LT(1).getText().equalsIgnoreCase("found")}? ID;
kINDICES : {_input.LT(1).getText().equalsIgnoreCase("indices")}? ID;
kMOD : {_input.LT(1).getText().equalsIgnoreCase("mod")}? ID;
kNAME : {_input.LT(1).getText().equalsIgnoreCase("name")}? ID;
//kOF : {_input.LT(1).getText().equalsIgnoreCase("of")}? ID;
kREPLACE : {_input.LT(1).getText().equalsIgnoreCase("replace")}? ID;
kROWCOUNT : {_input.LT(1).getText().equalsIgnoreCase("rowcount")}? ID;
//kSAVE : {_input.LT(1).getText().equalsIgnoreCase("save")}? ID;
//kSHOW : {_input.LT(1).getText().equalsIgnoreCase("show")}? ID;
//kTYPE : {_input.LT(1).getText().equalsIgnoreCase("type")}? ID;
kVALUES : {_input.LT(1).getText().equalsIgnoreCase("values")}? ID;

ALL : A L L ;
AND :    A N D ;
ANY :    A N Y ;
ARRAY :  A R R A Y ;
AS : A S ;
ASC : A S C ( E N D I N G )?;
AT : A T ;
AUTHID: A U T H I D ;
BETWEEN : B E T W E E N ;
BODY    :   B O D Y ;
BOTH	: B O T H ;
BULK: B U L K ;
BULK_ROWCOUNT: B U L K '_' R O W C O U N T ;
BULK_EXCEPTIONS: B U L K '_' E X C E P T I O N S;
BY  :   B Y;
BYTE  :   B Y T E ;
CASE: C A S E;
CAST: C A S T;
CHAR: C H A R ;
CHECK: C H E C K ;
CREATE: C R E A T E;
CROSS: C R O S S;
COLLECT:    C O L L E C T ;
COUNT: C O U N T ;
COMMIT  :   C O M M I T;
CONNECT	: C O N N E C T ;
CONSTRAINT	: C O N S T R A I N T;
CUBE	:	C U B E ;
CURRENT: C U R R E N T ;
CURRENT_USER: C U R R E N T '_' U S E R;
CURRVAL :   C U R R V A L ;
DATE	:	D A T E ;
DAY	:	D A Y;
DEFAULT : D E F A U L T ;
DEFINER: D E F I N E R;
DELETE  :   D E L E T E;
DENSE_RANK: D E N S E '_' R A N K ;
DESC: D E S C ( E N D I N G )? ;
DISTINCT : D I S T I N C T ;
ELSE : E L S E ;
ELSIF   :   E L S I F ;
ERRORS  :   E R R O R S; 
ESCAPE	:	E S C A P E ;
EXCEPTIONS: E X C E P T I O N S ;
EXCLUDE: E X C L U D E;
EXTERNAL:   E X T E R N A L;
EXTRACT:	E X T R A C T ;
FALSE   :   F A L S E ;
FETCH   :   F E T C H ;
FIRST   :   F I R S T ;
FOLLOWING: F O L L O W I N G ;
FOR : F O R  ;
FORALL : F O R A L L  ;
FORCE: F O R C E ;
FROM: F R O M ;
FULL: F U L L ;
GOTO    :   G O T O ;
GROUP	:	G R O U P ;
GROUPING	:	G R O U P I N G;
HAVING	: H A V I N G ;
HOUR	: H O U R ;
IF  :   I F ;
IN : I N  ;
INCLUDE : I N C L U D E ;
INDEX : I N D E X  ;
INFINITE: I N F I N I T E;
INNER  :   I N N E R;
INSERT  :   I N S E R T ;
INTERSECT: I N T E R S E C T ;
INTERVAL: I N T E R V A L ;
INTO    :   I N T O ;
IS : I S ;
JOIN: J O I N ;
KEEP: K E E P ;
LANGUAGE:   L A N G U A G E ;
LAST: L A S T ;
LEFT: L E F T ;
LEADING	: L E A D I N G ;
LIKE : L I K E  ;
LIKEC : L I K E C  ;
LIKE2 : L I K E '2' ;
LIKE4 : L I K E  '4' ;
LIMIT : L I M I T  ;
LISTAGG : L I S T A G G ;
LOCK    :   L O C K ;
LOCKED  :   L O C K E D  ;
LOG	:	L O G ;
MATCHED	:	M A T C H E D ;
MERGE	:	M E R G E ;
MINUS_SET : M I N U S ;
MINUTE : M I N U T E ;
MONTH	:	M O N T H ;
MULTISET: M U L T I S E T ;
NAME: N A M E ;
NAN: N A N ;
NATURAL : N A T U R A L ;
NEXTVAL :   N E X T V A L ;
NO : N O ;
NOCYCLE: N O C Y C L E  ;
NOT : N O T  ;
NOTFOUND:   N O T F O U N D ;
NOWAIT : N O W A I T;
NULL : N U L L  ;
NULLS : N U L L S ;
OF : O F ;
ON : O N  ;
ONLY  : O N L Y ;
OPEN    :   O P E N ;
OPTION: O P T I O N ; 
OR : O R  ;
ORDER : O R D E R  ;
OUTER: O U T E R ;
OVER: O V E R ;
OVERLAPS: O V E R L A P S;
PACKAGE: P A C K A G E;
PARTITION: P A R T I T I O N ;
PIPE	:	P I P E ;
PIVOT	:	P I V O T ;
PRECEDING: P R E C E D I N G ;
PRIOR: P R I O R ;
RAISE   :   R A I S E ;
RANGE 	: R A N G E ;
RAW:	R A W ;
READ: R E A D ;
REPLACE	:	R E P L A C E ;
REVERSE	:	R E V E R S E ;
REJECT	:	R E J E C T ;
RIGHT : R I G H T ;
ROLLBACK:   R O L L B A C K ;
ROLLUP:	R O L L U P;
ROW: R O W  ;
ROWS: R O W S ;
ROWID: R O W I D ;
ROWNUM: R O W N U M ;
SAVEPOINT   :   S A V E P O I N T ;
SECOND	:	S E C O N D ;
SELECT  :   S E L E C T ;
SET :   S E T ;
SETS :   S E T S;
SHOW    :   S H O W;
SIBLINGS : S I B L I N G S ;
SKIPl	:	S K I P ;
SQL :   S Q L ;
START	: S T A R T ;
TABLE   :   T A B L E ;
THE : T H E ;
THEN : T H E N  ;
TIMEZONE_ABBR	: T I M E Z O N E '_' A B B R ;
TIMEZONE_HOUR	: T I M E Z O N E '_' H O U R ;
TIMEZONE_MINUTE	: T I M E Z O N E '_' M I N U T E ;
TIMEZONE_REGION	: T I M E Z O N E '_' R E G I O N ;
TO: T O ;
TRAILING	:	T R A I L I N G ;
TRANSACTION :   T R A N S A C T I O N ;
TRIM	:	T R I M ;
TRUE    :   T R U E ;
TYPE	: 	T Y P E ;
UNION: U N I O N;
UNIQUE: U N I Q U E;
UPDATE  :   U P D A T E ;
UNLIMITED:	U N L I M I T E D ;
UNPIVOT	:	U N P I V O T ;
VALUE	: V A L U E ;
VALUES	: V A L U E S ;
VIEW	:	V I E W ;
WAIT : W A I T;
WHERE   :   W H E R E ;
WHILE   :   W H I L E ;
WITH	: 	W I T H ;
WITHIN	: 	W I T H I N ;
XML	:	X M L;
XMLAGG	:	X M L A G G ;
XMLATTRIBUTES	:	X M L A T T R I B U T E S;
XMLELEMENT	:	X M L E L E M E N T;
YEAR	: 	Y E A R;

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
SAVE    :   S A V E ;
SUBTYPE :   S U B T Y P E    ;
USING:  U S I N G  ;
UNBOUNDED 	:	U N B O U N D E D ;
VARRAY  :   V A R R A Y     ;
VARYING :   V A R Y I N G    ;
WHEN    :   W H E N   ;

QUOTED_STRING
	:	( 'n' )? '\'' ( '\'\'' | ~('\'') )* '\''
	;

ID
	:	( 'a' .. 'z' | 'A' .. 'Z' )
		( 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '$' | '#' | ICELANDIC_LETTER )*
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
	:	'=' WS* '>'
	;
VERTBAR
	:	'|'
	;
DOUBLEVERTBAR
	:	'||'
	;
NOT_EQ
	:	'<' WS* '>' | '!' WS* '=' | '~' WS* '='| '^' WS* '='
	;
LTH
	:	'<'
	;
LEQ
	:	'<' WS* '='
	;
GTH
	:	'>'
	;
GEQ
	:	'>' WS* '='
	;
OUTER_PLUS
	:	'(+)'
	;
INTEGER
    :   NUM
    ;
REAL_NUMBER
	:	NUMBER_VALUE	( E ( PLUS | MINUS )? NUM )?
	;
fragment
NUMBER_VALUE
	:	NUM POINT NUM  //{numberDotValid()}?=> NUM POINT NUM?
	|	POINT NUM ( D | F )?
	|	NUM ( D | F )?
	;
fragment
NUM
	: '0' .. '9' ( '0' .. '9' )*
	;
fragment
DOUBLEQUOTED_STRING
	:	'"' ( ~('"') | ICELANDIC_LETTER )* '"'
	;
WS	:	(' '|'\r'|'\t'|'\n') -> skip
	;
SL_COMMENT
	:	'--'~('\n'|'\r')* '\r'?  ( '\n' | EOF ) ->skip
	;
ML_COMMENT
	:	'/*' ( . )*? '*/' -> skip
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
fragment ICELANDIC_LETTER: ( 'á'|'Á'| 'Ð'|'ð'|'É'|'é'|'Í'|'í'|'Ó'|'ó'|'Ú'|'ú'|'Ý'|'ý'|'Þ'|'þ'|'Æ'|'æ'|'Ö'|'ö');
