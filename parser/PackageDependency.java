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

	public PackageDependency(ReferenceResolver resolver) 
	{
		this.resolver=resolver;
	}

	public void enterCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
		if(ctx.schema_name != null) 
			currentSchema=ctx.schema_name.getText();
		else
			currentSchema="UNKN";
		currentPackage=ctx.package_name.getText();
		System.out.println("entering package "+currentSchema+"."+currentPackage);
		resolver.registerElement(currentPackage,"package");
		resolver.pushContext(currentPackage,"package");
		
	}

	public void exitCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 	
		currentSchema="";
		currentPackage="";
		resolver.popContext();
		
	}

	public void enterVariable_declaration(PLSQLParser.Variable_declarationContext ctx) 
	{ 
		resolver.registerElement(ctx.variable_name.getText(),"variable");
		System.out.println("variable:"+ctx.variable_name.getText());
		
	}	

	public void handleEnterProcDef(String procName)
	{
		//we don't want to keep track of dependencies of nested functions, they will be registered as 
		// paraet function reference
		if(currentProc.equals("")) {
			currentProc=procName;
		}
		resolver.registerElement(currentProc,"procedure");
		resolver.pushContext(currentProc,"procedure");

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
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
		handleEnterProcDef(ctx.procedure_name.getText());
		
	}
	
	
	public void exitProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		handleExitProcDef(ctx.procedure_name.getText());
		
	}

	/*public void exitProcedure_heading(PLSQLParser.Procedure_headingContext ctx) 
	{ 
		currentProc="";
	}*/
	public void enterFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
		handleEnterProcDef(ctx.function_name.getText());	
	}

	public void exitFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		handleExitProcDef(ctx.function_name.getText());
	}

	public void handleProcFuncCall(List<PLSQLParser.CallContext> prefix,PLSQLParser.CallContext element) 
	{ 
		String calledSchema =  "";
		String calledPackage = "";
		String calledProc = element.id.getText();
		PLSQLElement ref;
		if(prefix.size()==2) {
			calledSchema=prefix.get(0).id.getText();
			calledPackage=prefix.get(1).id.getText();
		} else if (prefix.size()==1) {
			calledSchema=currentSchema;
			calledPackage=prefix.get(0).id.getText();;
		}
		ref=resolver.findElement(element.id.getText());
		if(ref != null ) 
			System.out.println(ref.name+" <"+ref.type+">");

		System.out.println(calledPackage);
		System.out.println(currentSchema+"."+currentPackage+"."+currentProc+"->"+calledSchema+"."+calledPackage+"."+calledProc );
	}

	public void enterVariable_or_function_call(PLSQLParser.Variable_or_function_callContext ctx) 
	{ 
		//handleCallContext(ctx);
		handleProcFuncCall(ctx.prefix,ctx.element);
		System.out.println("Prefix: " + ctx.prefix);
		System.out.println("Function_call: " + ctx.element.getText());
	}
	
	public void enterCall_statement(PLSQLParser.Call_statementContext ctx) 
	{ 
		//handleCallContext(ctx.getRuleContext(PLSQLParser.LvalueContext.class,0));
		handleProcFuncCall(ctx.prefix,ctx.element);
		System.out.println("Prefix: " + ctx.prefix);
		System.out.println("Procedure call: " + ctx.element.getText());
	}

	public static void parse(CharStream stream,ReferenceResolver resolver) {
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
		
    	PackageDependency listener = new PackageDependency(resolver);

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
 		parse(new ANTLRFileStream(args[0]),new ReferenceResolver());

	}

}