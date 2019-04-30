parser grammar PLSQLParser;


options { 
    tokenVocab=PLSQLLexer;
}
script
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
        param=ident ( IN | ( ( OUT | IN OUT ) NOCOPY? ) )? datatype
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
        CURSOR cursor_name=ident parameter_declarations? IS select_statement
    ;

item_declaration
    : variable_declaration
    | constant_declaration
    | exception_declaration
    ;

variable_declaration :
        variable_name=ident datatype (  (  NOT NULL )? ( ASSIGN  | DEFAULT )? expression  )?
    ;

constant_declaration :
        constant_name=ident CONSTANT datatype ( NOT NULL )? ( ASSIGN  | DEFAULT  ) expression
    ;

exception_declaration :
        ident EXCEPTION
    ;

type_definition :
        TYPE ident IS ( record_type_definition | collection_type_definition | ref_cursor_type_definition )
    ;

subtype_definition :
        SUBTYPE ident IS datatype ( NOT NULL )?
    ;
    
record_type_definition :
	RECORD LPAREN record_field_declaration ( COMMA record_field_declaration )* RPAREN
    ;

record_field_declaration :
	ident datatype ( ( NOT NULL )? ( ASSIGN | DEFAULT ) expression )?
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
    :  ( REF )? elements+=ident ( DOT elements+=ident )* dblink?( LPAREN numeric_literal ( COMMA numeric_literal )* ( BYTE | CHAR )? RPAREN | PERCENT objtype=( TYPE | ROWTYPE ) | RAW )?
	| ROWID
    ;

function_declaration_or_definition :
        FUNCTION function_name=ident parameter_declarations? RETURN datatype
        ( DETERMINISTIC | PIPELINED | PARALLEL_ENABLE | RESULT_CACHE )*
        ( ( IS | AS ) ( declare_section? body  | call_spec) )?
	;

procedure_declaration_or_definition :
        PROCEDURE procedure_name=ident parameter_declarations?
        ( ( IS | AS ) ( declare_section? body | call_spec ) )?
    ;
	
body 	:	
	BEGIN statement SEMI ( statement SEMI | pragma SEMI )*
	( EXCEPTION exception_handler+ )? END ident?
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
    : COLON? name=ident ( LPAREN ( parameter ( COMMA parameter )* )? RPAREN )*
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
        CLOSE ident ( DOT ident )?
    ;

continue_statement :
        CONTINUE ( lbl=ident )? ( WHEN expression )?
    ;

execute_immediate_statement :
        EXECUTE IMMEDIATE expression (
        ( into_clause | bulk_collect_into_clause) using_clause?
        | using_clause dynamic_returning_clause?
        | dynamic_returning_clause
        )?
    ;

exit_statement :
        EXIT ( lbl=ident )? ( WHEN expression )?
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
		FOR variable_name=ident IN ( LPAREN select_statement RPAREN | call_statement )  LOOP 
			( statement SEMI )+ END LOOP label_name?
	|	FOR variable_name=ident IN REVERSE? expression DOUBLEDOT expression LOOP
			( statement SEMI )+ END LOOP label_name?
    ;

forall_statement :
        FORALL variable_name=ident IN bounds_clause ( SAVE EXCEPTIONS )? sql_statement 
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
        OPEN ident ( DOT ident )* call_args? ( FOR ( select_statement | expression ) using_clause? )?
    ;
/*using_clause :
	USING ( IN | OUT | IN OUT)? parameter ( COMMA? parameter )*
	;
*/
pragma :
        PRAGMA swallow_to_semi
    ;

raise_statement :
        RAISE ( ident ( DOT ident )* )?
    ;

return_statement :
        RETURN expression?
    ;

plsql_block :
        ( DECLARE declare_section? )? body
    ;

label :
        LLABEL label_id=ident RLABEL
    ;
pipe_row_statement:
	PIPE ROW LPAREN expression RPAREN
	;
qual_id :
	COLON? ident ( DOT COLON? ident )*
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
        DELETE FROM? ( dml_table_expression_clause  | ONLY LPAREN dml_table_expression_clause RPAREN ) t_alias=ident?
		( where_clause | WHERE CURRENT OF ident )? returning_clause? error_logging_clause?
    ;

insert_statement :
	//INSERT swallow_to_semi
	INSERT /*hint?*/ ( single_table_insert  /*| multi_table_insert */)
    ;

single_table_insert:
	insert_into_clause ( values_clause ( returning_clause )? | select_statement ) /*error_logging_clause? */
	;

insert_into_clause:
	INTO dml_table_expression_clause (t_alias=ident)? ( LPAREN (ident DOT )? columns+=ident ( COMMA (ident DOT )?columns+=ident )* RPAREN )?
	;
dblink:
	AT_SIGN name=ident ( DOT domain+=ident )*
	;

dml_table_expression_clause:
	( schema=ident DOT )? table=ident ( dblink?  /*|partition_extension_clause */ )? # dml_table_def
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
        SAVEPOINT ident
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
	( (schema=ident DOT )? table=ident  DOT )? column=ident
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
	WITH query_name=ident AS LPAREN subquery RPAREN ( COMMA query_name=ident AS LPAREN subquery RPAREN )*
	;

select_list :
	ASTERISK
	| select_element ( COMMA select_element )*
	;
	
select_element:
	ident ( DOT ident )? DOT ASTERISK
	| expr ( AS? ident )?
	;

table_reference:
	( ONLY LPAREN query_table_expression RPAREN 
		| query_table_expression ( pivot_clause  | unpivot_clause  )?
	)  /*flashback_query_clause? */ (t_alias=ident)?
	;

query_table_expression:
	/* query_name
	|*/ ( schema=ident DOT)?  table=ident ( dblink?   /*|partition_extension_clause */ )? /*sample_clause?*/ # query_table_def
	| THE? LPAREN subquery_factoring_clause? subquery subquery_restriction_clause? RPAREN # query_subquery
	| table_collection_expression  # query_table_cast
	| LPAREN from_element RPAREN # query_table_paren
	;
subquery_restriction_clause:
	WITH ( READ ONLY | CHECK OPTION ) (CONSTRAINT ident)?
	;
	
table_collection_expression:
	TABLE LPAREN expr RPAREN  // should be collection expr 
	| TABLE LPAREN subquery RPAREN  // should be collection expr 
	;

pivot_clause:
		PIVOT XML? LPAREN pivot_element ( COMMA pivot_element )* pivot_for_clause pivot_in_clause  RPAREN
	;
	
pivot_element:
	aggregate_func=ident LPAREN expr RPAREN (AS? alias=ident)?
	;
	
pivot_for_clause:
	FOR ( colmns += ident | LPAREN columns += ident ( COMMA columns += ident )* RPAREN )
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
	 ) ( AS? alias=ident)
	 ;

unpivot_clause:
	UNPIVOT ( ( INCLUDE | EXCLUDE ) NULLS )? 
	LPAREN (
		culumns+=ident
		| LPAREN columns+=ident ( COMMA columns+=ident )* RPAREN
	) pivot_for_clause unpivot_in_clause  RPAREN
	;
unpivot_in_clause:
	IN LPAREN 
		unpivot_in_element ( COMMA unpivot_in_element)*
	RPAREN
	;
unpivot_in_element:
	( columns+=ident | LPAREN  columns+=ident ( COMMA columns+=ident )* RPAREN )
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
	INNER? JOIN table_reference ( ON condition | USING LPAREN columns+=ident ( COMMA columns+=ident)* RPAREN ) 
	| ( CROSS | NATURAL INNER? ) JOIN table_reference
	;
	
outer_join_clause:
	/* query_partition_clause? */ ( outer_join_type  | NATURAL outer_join_type ) JOIN 
		table_reference  /* query_partition_clause */ 
		( ON condition | USING LPAREN columns+=ident ( COMMA columns+=ident)* )
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
	MERGE INTO dml_table_expression_clause  t_alias=ident? //--( schema=ident DOT)?  table=ident  t_alias=ident? */
	USING  dml_table_expression_clause  u_alias=ident?     //--(  ( u_schema=ident DOT)?  u_table=ident  | subquery ) u_alias=ident? 
	ON LPAREN condition RPAREN
	merge_update_clause? merge_insert_clause? error_logging_clause?
	;
	
merge_update_clause:
	WHEN MATCHED THEN UPDATE SET merge_update_column ( COMMA merge_update_column )*
	where_clause? ( DELETE where_clause)?
	;

merge_update_column:
	( prefix=ident DOT)? column=ident EQ ( expr | DEFAULT ) 
	;


merge_insert_clause:
	WHEN NOT MATCHED THEN INSERT ( LPAREN (ident DOT )? columns+=ident ( COMMA (ident DOT )?columns+=ident )* RPAREN )?
	values_clause where_clause?
;

error_logging_clause:
	LOG ERRORS ( INTO (schema=ident)? table=ident )? ( LPAREN simple_expression )
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
    ((schema=ident DOT )? table=ident DOT)? (column=ident | ROWID ) ( OUTER_PLUS )?
    | ROWNUM 
    | string_literal
	| date_literal
    | numeric_literal
	| interval_literal
	| boolean_literal // booleans is not really part of Oracle SQL, but need this here until I have a stricter separation between SQL and PL/SQL
    | elements+=ident ( DOT elements+=ident)* DOT ( CURRVAL | NEXTVAL)
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
	//((schema=ident DOT )? table=ident DOT)? function=ident LPAREN expr ( COMMA expr)* RPAREN
	elements+=ident ( DOT elements+=ident)* LPAREN sql_param ( COMMA sql_param)* RPAREN
	| CAST LPAREN ( expr | MULTISET LPAREN subquery RPAREN ) AS ident ( DOT ident )* ( LPAREN INTEGER ( COMMA INTEGER)? ( BYTE | CHAR)? RPAREN )?  RPAREN
	| extract_function_datetime
	| trim_function
	| object_reference_function ( DOT ( function_expression | ident ) )* // Not in oracle docs
	| xmlelement_function
	| first_last_function
	;

sql_param 
    : ( ident ARROW )? expr
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
	XMLELEMENT LPAREN  NAME? ident ( COMMA xml_attributes_clause )? ( COMMA expr /* value_expr in oracle docs */  ( AS ident )?)* RPAREN 
	;

xml_attributes_clause:
	XMLATTRIBUTES LPAREN expr /* value_expr in oracle docs */ ( AS ident )? ( COMMA expr /* value_expr in oracle docs */ ( AS  ident )? )*
	;
xmlagg_function:
	XMLAGG LPAREN expr order_by_clause? RPAREN 
	;

first_last_function:
	aggr_function+=ident LPAREN sql_param  RPAREN KEEP 
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
	( ident  LPAREN ( expr ( COMMA expr )*  )? RPAREN
		| aggregate_function 
	)  ( IGNORE NULLS )? OVER LPAREN analytic_clause RPAREN
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
	ident LPAREN ( ASTERISK | ( DISTINCT | UNIQUE | ALL )?  expr ) RPAREN 
	;
	
value_expr:
	expression
	;
	
set_transaction_statement :
        SET TRANSACTION swallow_to_semi
    ;

update_statement :
        UPDATE  ( dml_table_expression_clause  | ONLY LPAREN dml_table_expression_clause RPAREN ) t_alias=ident?
		update_set_clause ( where_clause | WHERE CURRENT OF ident )? returning_clause? error_logging_clause?
    ;
update_set_clause:
	SET ( update_set_element ( COMMA update_set_element )*  | VALUE LPAREN ident RPAREN  EQ ( expr | LPAREN subquery RPAREN))
	;
	

update_set_element:
	( 	LPAREN update_column ( COMMA update_column)* RPAREN EQ LPAREN subquery RPAREN 
	  | update_column EQ ( expr | LPAREN select_statement RPAREN  | DEFAULT ) 
	)
	;

update_column:
		ident ( DOT ident )*
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

label_name:	ident;
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
	| CAST LPAREN  expression  AS ident ( DOT ident )* ( LPAREN INTEGER ( COMMA INTEGER)? ( BYTE | CHAR)? RPAREN )?  RPAREN

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
    : ident DOT EXISTS LPAREN expression RPAREN
    ;

conditional_predicate
    : INSERTING
    | UPDATING ( LPAREN QUOTED_STRING RPAREN )?
    | DELETING
    ;

parameter
    : ( ident ARROW )? expression
    ;

index
    : expression
    ;

create_package :
        CREATE ( OR REPLACE )? PACKAGE ( schema_name=ident DOT )? package_name=ident
        ( invoker_rights_clause )?
        ( IS | AS ) ( declare_section )? END ( ident )? SEMI
    ;

create_package_body :
        CREATE ( OR REPLACE )? PACKAGE BODY  (schema_name=ident DOT)?  package_name=ident
        ( IS | AS ) ( declare_section )?
        ( initialize_section=body | END ( package_name2=ident )? )
        SEMI
    ;

create_procedure :
        CREATE ( OR REPLACE )? PROCEDURE ( schema_name=ident DOT )? procedure_name=ident
        ( LPAREN parameter_declaration ( COMMA parameter_declaration )* RPAREN )?
        invoker_rights_clause?
        ( IS | AS )
        ( declare_section? body
        | call_spec
        | EXTERNAL
        ) SEMI
    ;

create_function :
        CREATE ( OR REPLACE )? FUNCTION ( schema_name=ident DOT )? function_name=ident
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
	(schema_name=ident DOT )? view_name=ident ( LPAREN ( alias+=ident /*( inline_constraint)*/ /*| out_of_line_constraint*/ ) 
		( COMMA ( alias+=ident /*( inline_constraint)*/ /*| out_of_line_constraint*/ ) ) *  RPAREN )?
	AS subquery_factoring_clause? subquery  ( subquery_restriction_clause )? 
	;
	
ident:
    ID | ERRORS | EXCEPTIONS | SAVE | SHOW | COUNT | DELETE | TYPE | FIRST | LAST | RIGHT | LEFT | REPLACE | ROW | LANGUAGE 
	| YEAR| MONTH | DAY | HOUR | MINUTE | SECOND | EXTRACT | AT | DATE | TRIM | WAIT | SKIPl | LOCKED | OF | NOWAIT  | NO
	| OPEN | AS | TO | INTERVAL | EXECUTE | CHAR | BYTE | LOG | WITH | ESCAPE | ROWS | REVERSE | SQL | ROWID | PACKAGE | FUNCTION
	| CROSS | RECORD | NAME | PIPE | COMMIT | CURRENT_USER |LIMIT | PRIOR | EXISTS | NOTFOUND | REF |BODY |  TRANSACTION 
	| SUBTYPE | EXTERNAL | FULL | LAST | IF | DENSE_RANK | RAW | READ | VALUE | BULK | IGNORE
    ;
	
id_func:
	ident 
	|DISTINCT 
	;

//kERRORS : {_input.LT(1).getText().length() >= 3 && "errors".startsWith(_input.LT(1).getText().toLowerCase())}? ID;
//kEXCEPTIONS : {_input.LT(1).getText().equalsIgnoreCase("exceptions")}? ID;
//kFOUND : {_input.LT(1).getText().equalsIgnoreCase("found")}? ID;
kFOUND : {$text.lower()=="found"}? ID;
//kINDICES : {_input.LT(1).getText().equalsIgnoreCase("indices")}? ID;
kINDICES : {$text.lower()=="indices"}? ID;
//kMOD : {_input.LT(1).getText().equalsIgnoreCase("mod")}? ID;
kMOD : {$text.lower()=="mod"}? ID;
//kNAME : {_input.LT(1).getText().equalsIgnoreCase("name")}? ID;
kNAME : {$text.lower()=="name"}? ID;
//kOF : {_input.LT(1).getText().equalsIgnoreCase("of")}? ID;
//kREPLACE : {_input.LT(1).getText().equalsIgnoreCase("replace")}? ID;
kREPLACE : {$text.lower()=="replace"}? ID;
//kROWCOUNT : {_input.LT(1).getText().equalsIgnoreCase("rowcount")}? ID;
kROWCOUNT : {$text.lower()=="rowcount"}? ID;
//kSAVE : {_input.LT(1).getText().equalsIgnoreCase("save")}? ID;
//kSHOW : {_input.LT(1).getText().equalsIgnoreCase("show")}? ID;
//kTYPE : {_input.LT(1).getText().equalsIgnoreCase("type")}? ID;
//kVALUES : {_input.LT(1).getText().equalsIgnoreCase("values")}? ID;
kVALUES : {$text.lower()=="values"}? ID;
//VALUES: V A L U E S ;

