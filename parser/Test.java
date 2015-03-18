import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.tree.*;
import org.antlr.v4.runtime.*;
//import org.antlr.v4.runtime.debug.*;
import java.io.IOException;

class Test extends PLSQLBaseListener 
{
	String currentSchema;
	String currentPackage;
	String currentProc;
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
		
	}
	public void exitCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 	
		currentSchema="";
		currentPackage="";	
		
	}

	public void enterProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
		currentProc= ctx.procedure_name.getText();
	}
	public void exitProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		currentProc="";
	}

	/*public void exitProcedure_heading(PLSQLParser.Procedure_headingContext ctx) 
	{ 
		currentProc="";
	}*/
	public void enterFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
		currentProc= ctx.function_name.getText();
	}

	public void exitFunction_declaration_or_definition(PLSQLParser.Function_declaration_or_definitionContext ctx) 
	{ 
		currentProc="";
	}

	public void enterFunction_heading(PLSQLParser.Function_headingContext ctx) 
	{ 	
		TerminalNode tn = ctx.getToken(PLSQLLexer.ID,0);
		currentProc= tn.getSymbol().getText();
		System.out.println(tn);
	}
	public void handleCallContext(ParserRuleContext ctx) 
	{ 
		String callingPackage="";
		String callingProc = "";
		PLSQLParser.CallContext cctx;
		java.util.List<PLSQLParser.CallContext> cctxs = ctx.getRuleContexts(PLSQLParser.CallContext.class); 
		System.out.println(cctxs);
		if(cctxs.size()==2) {
			callingPackage=cctxs.get(0).getToken(PLSQLLexer.ID,0).getSymbol().getText();
			callingProc=cctxs.get(1).getToken(PLSQLLexer.ID,0).getSymbol().getText();
		} else if (cctxs.size()==1) {
			callingPackage=currentPackage;
			callingProc=cctxs.get(0).getToken(PLSQLLexer.ID,0).getSymbol().getText();
			System.out.println("Bingo");
		}
		System.out.println(callingPackage);
		System.out.println(currentSchema+"."+currentPackage+"."+currentProc+"->"+callingPackage+"."+callingProc );
	}

	public void enterVariable_or_function_call(PLSQLParser.Variable_or_function_callContext ctx) 
	{ 
		handleCallContext(ctx);
	}
	public void enterAssign_or_call_statement(PLSQLParser.Assign_or_call_statementContext ctx) 
	{ 
		handleCallContext(ctx.getRuleContext(PLSQLParser.LvalueContext.class,0));
	}

public static void parse(String file) {
    try {
        PLSQLLexer lex = new PLSQLLexer(new ANTLRFileStream(file));
        CommonTokenStream tokens = new CommonTokenStream(lex);
       /* System.out.println(tokens);

        for( int i = 0; i < tokens.size();i++) {
            Token tk = tokens.get(i);
            System.out.println(tk);  
        }*/

        PLSQLParser parser = new PLSQLParser(tokens);

        PLSQLParser.FileContext fileContext = parser.file();
        ParseTreeWalker walker = new ParseTreeWalker();
    	Test listener = new Test();
    	walker.walk(listener, fileContext);

       

    } catch (RecognitionException e) {
        System.err.println(e.toString());
    } catch (IOException e) {
        System.err.println(e.toString());
    } catch (java.lang.OutOfMemoryError e) {
        System.err.println(file + ":");
        System.err.println(e.toString());
    } catch (java.lang.ArrayIndexOutOfBoundsException e) {
        System.err.println(file + ":");
        System.err.println(e.toString());
    }       
}

	public static void main(String args[])
	{
 		parse(args[0]);

	}

}