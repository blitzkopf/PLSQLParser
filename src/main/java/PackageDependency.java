import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.tree.*;
import org.antlr.v4.runtime.*;
//import org.antlr.v4.runtime.debug.*;
import java.io.IOException;
import java.util.List;



class PackageDependency extends PLSQLBaseListener 
{
	String currentSchema="";
	String currentObject="";
	String currentProc="";
	String currentType="";
	
	int currentPackStartLine = 0;
	ReferenceResolver resolver;

	public PackageDependency(ReferenceResolver resolver,String schema) 
	{
		this.resolver=resolver;
		this.currentSchema=schema;
	}
	public static String upUnq(String item) 
	{
		if(item.charAt(0) == '"') {
			return item.substring(1,item.length()-1);
		} else {
			return item.toUpperCase();
		}
	}

	public void enterCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		if(ctx.schema_name != null) 
			currentSchema=upUnq(ctx.schema_name.getText());
		currentObject=upUnq(ctx.package_name.getText());
		currentPackStartLine = ctx.getStart().getLine();
		//System.out.println("entering package "+currentSchema+"."+currentObject);
		resolver.pushScope(currentObject,"package");
		resolver.deregisterPackage(currentSchema,currentObject);
		
	}
	public void exitCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 	
		currentSchema="";
		currentObject="";
		resolver.popScope();
		
	}
	public void enterCreate_procedure(PLSQLParser.Create_procedureContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		if(ctx.schema_name != null) 
			currentSchema=upUnq(ctx.schema_name.getText());
		currentObject=upUnq(ctx.procedure_name.getText());
		currentPackStartLine = ctx.getStart().getLine();
		//System.out.println("entering procedure "+currentSchema+"."+currentObject);
		resolver.pushScope(currentObject,"procedure");
		resolver.deregisterPackage(currentSchema,currentObject);
		
	}
	public void exitCreate_procedure(PLSQLParser.Create_procedureContext ctx) 
	{ 	
		currentSchema="";
		currentObject="";
		resolver.popScope();
		
	}	
	public void enterCreate_function(PLSQLParser.Create_functionContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		if(ctx.schema_name != null) 
			currentSchema=upUnq(ctx.schema_name.getText());
		currentObject=upUnq(ctx.function_name.getText());
		currentPackStartLine = ctx.getStart().getLine();
		//System.out.println("entering function "+currentSchema+"."+currentObject);
		resolver.pushScope(currentObject,"function");
		resolver.deregisterPackage(currentSchema,currentObject);
		
	}
	public void exitCreate_function(PLSQLParser.Create_functionContext ctx) 
	{ 	
		currentSchema="";
		currentObject="";
		resolver.popScope();
		
	}	
	public void enterCreate_view(PLSQLParser.Create_viewContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		if(ctx.schema_name != null) 
			currentSchema=upUnq(ctx.schema_name.getText());
		currentObject=upUnq(ctx.view_name.getText());
		currentPackStartLine = ctx.getStart().getLine();
		//System.out.println("entering view "+currentSchema+"."+currentObject);
		resolver.pushScope(currentObject,"view");
		resolver.deregisterPackage(currentSchema,currentObject);
		
	}

	public void exitCreate_view(PLSQLParser.Create_viewContext ctx) 
	{ 	
		currentSchema="";
		currentObject="";
		resolver.popScope();
		
	}

	public void enterParameter_declaration(PLSQLParser.Parameter_declarationContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.param.getText()),"parameter");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}
	
	public void enterVariable_declaration(PLSQLParser.Variable_declarationContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.variable_name.getText()),"variable");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}
	public void enterCursor_definition(PLSQLParser.Cursor_definitionContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.cursor_name.getText()),"variable");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}
	
	public void enterFor_loop_statement(PLSQLParser.For_loop_statementContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.variable_name.getText()),"variable");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}

	public void handleEnterProcDef(ParserRuleContext ctx,String procName,String procType)
	{
		int beginLine = ctx.getStart().getLine();
		int endLine  = ctx.getStop().getLine();
		//we don't want to keep track of dependencies of nested functions, they will be registered as 
		// paraet function reference
		if(currentProc.equals("")) {
			currentProc=procName;
			resolver.registerProcedureInfo(currentSchema,currentObject,currentProc,procType,beginLine,endLine);
			
		}
		resolver.registerElement(procName,"procedure");
		resolver.pushScope(procName,"procedure");
	}

	public void handleExitProcDef(String procName){
		// only reset proc name when exiting the outermost level of nested function
		// ACHTUNG: what about nested functions with the same name as parent function, is that allowed?
		if(currentProc.equals(procName)) {	
			currentProc="";
		}
		resolver.popScope();
	}

	
	public void enterProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		handleEnterProcDef(ctx,upUnq(ctx.procedure_name.getText()),"PROCEDURE");
		
	}
	
	
	public void exitProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		handleExitProcDef(upUnq(ctx.procedure_name.getText()));
		
	}

	/*public void exitProcedure_heading(PLSQLParser.Procedure_headingContext ctx) 
	{ 
		currentProc="";
	}*/
	public void enterFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		handleEnterProcDef(ctx,upUnq(ctx.function_name.getText()),"FUNCTION");	
	}

	public void exitFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		handleExitProcDef(upUnq(ctx.function_name.getText()));
	}

	public void handleProcFuncCall(List<PLSQLParser.CallContext>  elements) 
	{ 
		String calledSchema =  "";
		String calledPackage = "";
		String calledProc = "";
		PLSQLElement ref;
		if(elements.size() == 0) 
			return;
			
		ref=resolver.findElement(upUnq(elements.get(0).name.getText()),currentSchema,currentObject);
		//System.out.println(upUnq(elements.get(0).name.getText()) + "--");
		
		if(ref != null ) {
			//System.out.println("er refur!");
			if(ref.type.equals( "variable") || ref.ctxType.equals( "procedure")) {
				System.out.println("//"+ref.name+" ("+ref.ctxType+"->"+ref.type+ ")");
				return;
			} else if(ref.type.equals("procedure") && ref.ctxType.equals("package")) {
				//System.out.println(ref.objectOwner);
				if(ref.objectOwner == null) {
					
					calledSchema =currentSchema;
					calledPackage=currentObject;
				} else {
					calledSchema =ref.objectOwner;
					calledPackage=ref.objectName;
				}
				calledProc=ref.name;
			} else if(ref.type.equals("procedure") && ref.ctxType.equals("schema")) {
				//System.out.println(ref.objectOwner);
				if(ref.objectOwner == null) {
					
					calledSchema =currentSchema;
					calledPackage=ref.objectName;
				} else {
					calledSchema =ref.objectOwner;
					calledPackage=ref.objectName;
				}
				//calledProc=ref.name;
 			} else if("schema".equals(ref.type)) {
				calledSchema =upUnq(elements.get(0).name.getText());
				calledPackage=upUnq(elements.get(1).name.getText());
				if(elements.size()==3) 
					calledProc   = upUnq(elements.get(2).name.getText());
				else 
					calledProc   = "";
			}

			
		} else {
			/* simplistics version of finding the correct item referenced */
			if(elements.size()==3) {
				calledSchema =upUnq(elements.get(0).name.getText());
				calledPackage=upUnq(elements.get(1).name.getText());
				calledProc   = upUnq(elements.get(2).name.getText());
			} else if (elements.size()==2) {
				calledSchema =currentSchema;
				calledPackage=upUnq(elements.get(0).name.getText());
				calledProc   = upUnq(elements.get(1).name.getText());

			} else if (elements.size()==1) {
				calledSchema =currentSchema;
				calledPackage=currentObject;
				calledProc   = upUnq(elements.get(0).name.getText());

			}
		}
		//System.out.println(calledPackage);
		resolver.registerReference(currentSchema,currentObject,currentProc,calledSchema,calledPackage,calledProc,elements.get(0).getStart().getLine());
		//System.out.println("\""+currentSchema+"."+currentObject+"."+currentProc+"\"->\""+calledSchema+"."+calledPackage+"."+calledProc +"\"");
	}

	public void handleProcFuncCallSQL(List<PLSQLParser.IdContext>  elements) 
	{ 
		String calledSchema =  "";
		String calledPackage = "";
		String calledProc = "";
		PLSQLElement ref;
		if(elements.size() == 0) 
			return;
			
		ref=resolver.findElement(upUnq(elements.get(0).getText()),currentSchema,currentObject);
		//System.out.println(upUnq(elements.get(0).getText()) + "++");
		if(ref != null ) {
			//System.out.println("er refur!");
			if(ref.type.equals( "variable") || ref.ctxType.equals( "procedure")) {
				//System.out.println("//"+ref.name+" ("+ref.ctxType+"->"+ref.type+ ")");
				return;
			} else if(ref.type.equals("procedure") && ref.ctxType.equals("package")) {
				//System.out.println(ref.objectOwner);
				if(ref.objectOwner == null) {
					
					calledSchema =currentSchema;
					calledPackage=currentObject;
				} else {
					calledSchema =ref.objectOwner;
					calledPackage=ref.objectName;
				}
				calledProc=ref.name;
			} else if(( ref.type.equals("procedure") || ref.type.equals("table")) && ref.ctxType.equals("schema")) {
				//System.out.println(ref.objectOwner);
				//System.out.println(ref.objectName);
				if(ref.objectOwner == null) {
					
					calledSchema =currentSchema;
					calledPackage=ref.objectName;
				} else {
					calledSchema =ref.objectOwner;
					calledPackage=ref.objectName;
				}
				//calledProc=ref.name;
			} else if("schema".equals(ref.type)) {
				calledSchema =upUnq(elements.get(0).getText());
				calledPackage=upUnq(elements.get(1).getText());
				if(elements.size()==3) 
					calledProc   = upUnq(elements.get(2).getText());
				else 
					calledProc   = "";
			}
		} else {
			/* simplistics version of finding the correct item referenced */
			if(elements.size()==3) {
				calledSchema =upUnq(elements.get(0).getText());
				calledPackage=upUnq(elements.get(1).getText());
				calledProc   = upUnq(elements.get(2).getText());
			} else if (elements.size()==2) {
				calledSchema =currentSchema;
				calledPackage=upUnq(elements.get(0).getText());
				calledProc   = upUnq(elements.get(1).getText());

			} else if (elements.size()==1) {
				calledSchema =currentSchema;
				calledPackage=currentObject;
				calledProc   = upUnq(elements.get(0).getText());

			}
		}
		//System.out.println(calledPackage);
		resolver.registerReference(currentSchema,currentObject,currentProc,calledSchema,calledPackage,calledProc,elements.get(0).getStart().getLine());
		//System.out.println("\""+currentSchema+"."+currentObject+"."+currentProc+"\"->\""+calledSchema+"."+calledPackage+"."+calledProc +"\"");
	}
	
	public void enterVariable_or_function_call(PLSQLParser.Variable_or_function_callContext ctx) 
	{ 
		//handleCallContext(ctx);
		handleProcFuncCall(ctx.elements);
		//System.out.println("Elements: " + ctx.elements);
		//System.out.println("Function_call: " + ctx.element.getText());
	}
	
	public void enterCall_statement(PLSQLParser.Call_statementContext ctx) 
	{ 
		//handleCallContext(ctx.getRuleContext(PLSQLParser.LvalueContext.class,0));
		handleProcFuncCall(ctx.elements);
		//System.out.println("Prefix: " + ctx.prefix);
		//System.out.println("Procedure call: " + ctx.element.getText());
	}
	public void enterFunction_expression(PLSQLParser.Function_expressionContext ctx) 
	{ 
		//handleCallContext(ctx.getRuleContext(PLSQLParser.LvalueContext.class,0));
		handleProcFuncCallSQL(ctx.elements);
		//System.out.println("Prefix: " + ctx.prefix);
		//System.out.println("Procedure call: " + ctx.element.getText());
	}
	public void handleTableRef(ParserRuleContext ctx, ParserRuleContext schema,ParserRuleContext table) 
	{
		String referencedSchema ;
		String referencedTable ;
		if(schema != null )
			referencedSchema=upUnq(schema.getText());
		else
			referencedSchema=currentSchema;
		referencedTable=upUnq(table.getText());
		resolver.registerReference(currentSchema,currentObject,currentProc,referencedSchema,referencedTable,null,ctx.getStart().getLine());
		//System.out.println("\""+currentSchema+"."+currentObject+"."+currentProc+"\"->\""+referencedSchema+"."+referencedTable +"\"");

	}
	//public void enterQuery_table_expression(PLSQLParser.Query_table_expressionContext ctx) 
	public void enterQuery_table_def(PLSQLParser.Query_table_defContext ctx) 
	{ 
		handleTableRef(ctx,ctx.schema,ctx.table);
		/*System.out.println("//Query_table_expression");
		String referencedSchema =  "";
		String referencedTable = "";
		if(ctx.schema != null )
			referencedSchema=upUnq(ctx.schema.getText());
		else
			referencedSchema=currentSchema;
		referencedTable=upUnq(ctx.table.getText());
		resolver.registerReference(currentSchema,currentObject,currentProc,referencedSchema,referencedTable,null,ctx.getStart().getLine());
		//System.out.println("\""+currentSchema+"."+currentObject+"."+currentProc+"\"->\""+referencedSchema+"."+referencedTable +"\"");
		*/
	}

	//public void enterQuery_table_expression(PLSQLParser.Query_table_expressionContext ctx) 
	public void enterDml_table_def(PLSQLParser.Dml_table_defContext ctx) 
	{ 
		handleTableRef(ctx,ctx.schema,ctx.table);
	}
	public void enterDatatype(PLSQLParser.DatatypeContext ctx) 
	{ 
		if(ctx.type != null && ( ctx.type.getType() == PLSQLParser.TYPE || ctx.type.getType() == PLSQLParser.ROWTYPE) 
			||ctx.elements.get(0).getStart().getType() == PLSQLParser.ID ) 
		{
			//System.out.println("Type >>>"+ctx.type.getType());
			handleProcFuncCallSQL(ctx.elements);
			//System.out.println("Type >>>"+ctx.elements.get(0).getText());
		} else {
			//System.out.println("Type >>>"+ctx.elements.get(0).getText() +"."+ctx.elements.get(0).getStart().getType());
		}
	}
	
	public static void parse(CharStream stream,ReferenceResolver resolver, String schema,ANTLRErrorListener errListener) 
	{
    	try {
	        PLSQLLexer lex = new PLSQLLexer(stream);
	        CommonTokenStream tokens = new CommonTokenStream(lex);
	       /* System.out.println(tokens);

	        for( int i = 0; i < tokens.size();i++) {
	            Token tk = tokens.get(i);
	            System.out.println(tk);  
	        }*/

	        PLSQLParser parser = new PLSQLParser(tokens);
			if ( errListener != null ) 
				parser.addErrorListener(errListener);

	        PLSQLParser.FileContext fileContext = parser.file();
	        ParseTreeWalker walker = new ParseTreeWalker();
			
	    	PackageDependency listener = new PackageDependency(resolver,schema);

	    	walker.walk(listener, fileContext);

	    } catch (RecognitionException e) {
	        System.err.println(e.toString());
	    } catch (java.lang.OutOfMemoryError e) {
	        //System.err.println(file + ":");
	        System.err.println(e.toString());
	    } catch (java.lang.ArrayIndexOutOfBoundsException e) {
	        //System.err.println(file + ":");
	        System.err.println(e.toString());
	    }       
	}

	public static void main(String args[])
	throws IOException
	{
 		parse(new ANTLRFileStream(args[0]),new ReferenceResolver(),"",null);

	}

}