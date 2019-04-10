import org.antlr.v4.runtime.BaseErrorListener;
import org.antlr.v4.runtime.Recognizer;
import org.antlr.v4.runtime.RecognitionException;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.SQLException;

import java.lang.Math;


class DBLogErrorListener extends BaseErrorListener
{
	String owner;
	String name;
	String type;
	PreparedStatement insError, delErrors;
	
	public DBLogErrorListener(Connection conn )
	throws  SQLException
	{
		//this.conn=conn;
		try {
			insError=conn.prepareStatement("begin db_tools.pack_depend.Register_Parse_Error(?,?,?,?,?,?,?); end; ");
			delErrors=conn.prepareStatement("begin db_tools.pack_depend.delete_Parse_errors(?,?,?); end; ");
			
		} catch(SQLException e) {
			System.err.println(e);
		}
		
	}
	
	public void setParsingObject(String owner, String name, String type)	{
		this.owner=owner;
		this.name=name;
		this.type = type;
		try {
			delErrors.setString(1,owner);
			delErrors.setString(2,name);
			delErrors.setString(3,type);
			delErrors.execute();
		} catch(SQLException e) {
			//System.err.println(e);
			e.printStackTrace();
		}
	}
	public void syntaxError(Recognizer<?,?> recognizer,
               java.lang.Object offendingSymbol,
               int line,
               int charPositionInLine,
               java.lang.String msg,
               RecognitionException e)
	{
		
		System.out.println("Mange takk!"+e);
		try {
			insError.setString(1,owner);
			insError.setString(2,name);
			insError.setString(3,type);
			insError.setString(4,offendingSymbol.toString().substring(0,Math.min(100,offendingSymbol.toString().length())));
			insError.setInt(5,line);
			insError.setInt(6,charPositionInLine);
			insError.setString(7,msg);
			insError.execute();
		} catch(SQLException ex) {
			//System.err.println(ex);
			ex.printStackTrace();
		}

		
		
	}	
};

