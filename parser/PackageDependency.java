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
	String currentPackage="";
	String currentProc="";
	ReferenceResolver resolver;

	public PackageDependency(ReferenceResolver resolver,String schema) 
	{
		this.resolver=resolver;
		this.currentSchema=schema;
	}
	public static String upUnq(String item) 
	{
		if(item.charAt(0) == '"') {
			return item.substring(1,item.length()-2);
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
		currentPackage=upUnq(ctx.package_name.getText());
		System.out.println("entering package "+currentSchema+"."+currentPackage);
		resolver.pushContext(currentPackage,"package");
		//resolver.registerElement(currentPackage,"package");
		
	}

	public void exitCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 	
		currentSchema="";
		currentPackage="";
		resolver.popContext();
		
	}

	public void enterVariable_declaration(PLSQLParser.Variable_declarationContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.variable_name.getText()),"variable");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}
	public void enterFor_loop_statement(PLSQLParser.For_loop_statementContext ctx) 
	{ 
		resolver.registerElement(upUnq(ctx.variable_name.getText()),"variable");
		//System.out.println("variable:"+ctx.variable_name.getText());
		
	}

	public void handleEnterProcDef(String procName)
	{
		//we don't want to keep track of dependencies of nested functions, they will be registered as 
		// paraet function reference
		if(currentProc.equals("")) {
			currentProc=procName;
		}
		resolver.registerElement(procName,"procedure");
		resolver.pushContext(procName,"procedure");

	}

	public void handleExitProcDef(String procName){
		// only reset proc name when exiting the outermost level of nested function
		// ACHTUNG: what about nested functions with the same name as parent function, is that allowed?
		if(currentProc.equals(procName)) {	
			currentProc="";
		}
		resolver.popContext();
	}

	
	public void enterProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		//System.out.println(ctx.getStart());
		//System.out.println(ctx.getStop());
		handleEnterProcDef(upUnq(ctx.procedure_name.getText()));
		
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
		handleEnterProcDef(upUnq(ctx.function_name.getText()));	
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
		
		ref=resolver.findElement(upUnq(elements.get(0).name.getText()));
		
		if(ref != null ) {
			if(ref.type == "variable" || ref.ctxType == "procedure") {
				System.out.println("//"+ref.name+" ("+ref.ctxType+"->"+ref.type+ ")");
				return;
			} else if(ref.type=="procedure" && ref.ctxType == "package") {
				calledSchema =currentSchema;
				calledPackage=currentPackage;
				calledProc=ref.name;
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
				calledPackage=currentPackage;
				calledProc   = upUnq(elements.get(0).name.getText());

			}
		}
		//System.out.println(calledPackage);
		System.out.println("\""+currentSchema+"."+currentPackage+"."+currentProc+"\"->\""+calledSchema+"."+calledPackage+"."+calledProc +"\"");
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
	
	public void enterQuery_table_expression(PLSQLParser.Query_table_expressionContext ctx) 
	{ 
		System.out.println("//Query_table_expression");
		String referencedSchema =  "";
		String referencedTable = "";
		referencedSchema=upUnq(ctx.schema.getText());
		referencedTable=upUnq(ctx.table.getText());
		
		System.out.println("\""+currentSchema+"."+currentPackage+"."+currentProc+"\"->\""+referencedSchema+"."+referencedTable +"\"");
		
	}


	public static void parse(CharStream stream,ReferenceResolver resolver, String schema) 
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
 		parse(new ANTLRFileStream(args[0]),new ReferenceResolver(),"");

	}

}