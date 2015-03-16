import org.antlr.v4.runtime.ANTLRFileStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.RecognitionException;
import org.antlr.v4.runtime.tree.*;
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
		java.util.List<TerminalNode> tl = ctx.getTokens(PLSQLLexer.ID);
		if(tl.size() == 2) {
			currentSchema=tl.get(0).getSymbol().getText();
			currentPackage=tl.get(1).getSymbol().getText();
		} else if (tl.size()==1) {
			currentSchema="UNKN";
			currentPackage=tl.get(0).getSymbol().getText();
		}

		//TerminalNode tn = ctx.getToken(PLSQLLexer.ID,0);
		System.out.println(tl);
		
	}
	public void exitCreate_package_body(PLSQLParser.Create_package_bodyContext ctx) 
	{ 	
		currentSchema="";
		currentPackage="";	
		
	}

	/*public void enterProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		System.out.println(ctx.getStart());
		System.out.println(ctx.getStop());
	}*/
	public void exitProcedure_declaration_or_definition(PLSQLParser.Procedure_declaration_or_definitionContext ctx) 
	{ 
		currentProc="";
	}

	public void enterProcedure_heading(PLSQLParser.Procedure_headingContext ctx) 
	{ 	
		TerminalNode tn = ctx.getToken(PLSQLLexer.ID,0);
		currentProc= tn.getSymbol().getText();
		System.out.println(tn);
	}
	/*public void exitProcedure_heading(PLSQLParser.Procedure_headingContext ctx) 
	{ 
		currentProc="";
	}*/

	public void enterVariable_or_function_call(PLSQLParser.Variable_or_function_callContext ctx) 
	{ 
		String callingPackage="";
		String callingProc = "";
		PLSQLParser.CallContext cctx;
		java.util.List<PLSQLParser.CallContext> cctxs = ctx.getRuleContexts(PLSQLParser.CallContext.class); 
		System.out.println(cctxs);
		if(cctxs.size()==2) {
			callingPackage=cctxs.get(0).getToken(PLSQLLexer.ID,0).getSymbol().getText();
			callingProc=cctxs.get(1).getToken(PLSQLLexer.ID,0).getSymbol().getText();
		}
		System.out.println(callingPackage);
		System.out.println(currentSchema+"."+currentPackage+"."+currentProc+"->"+callingPackage+"."+callingProc );
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

        ///*start_rule_return AST =*/ parser.data_manipulation_language_statements();
        //parser.create_package();

        /*System.out.println(builder.getTree().toStringTree());

        System.err.println(file +": " + parser.getNumberOfSyntaxErrors());

        if(parser.getNumberOfSyntaxErrors() != 0)
        {
            //System.exit(1);
        }
        
        objInfo(builder.getTree());
*/

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
 		parse("test.sql");

	}

}