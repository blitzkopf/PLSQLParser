import org.antlr.v4.runtime.ANTLRInputStream;
//import org.antlr.v4.runtime.debug.*;
import java.io.IOException;
import java.sql.*;
import oracle.jdbc.*;
/*import org.apache.commons.cli.Options;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.CommandLineParser; 
import org.apache.commons.cli.CommandLine; 
import org.apache.commons.cli.ParseException; */

class DBDependency {
	static Connection conn;
	static DBLogErrorListener errListener;
	static DBRefResolver resolver;
	
	public static void parse(String owner,String name,String type)
	throws SQLException
	{
		String source;
		errListener.setParsingObject(owner,name,type);
		
		CallableStatement cs = conn.prepareCall("begin db_tools.recursive_audit_fga_ui.get_source(?,?,?,?); end;");
		try {
			cs.setString(1,owner);
			cs.setString(2,name);
			cs.setString(3,type);
			cs.registerOutParameter(4, OracleTypes.CURSOR);
			cs.execute();

			ResultSet cursor;
			
			cursor = ((OracleCallableStatement)cs).getCursor(4);
			try {
				
				if(type.equals( "VIEW"))
					source="create view \""+owner+"\".\""+ name +"\" as ";
				else 
					source="create ";
				while (cursor.next ()) {
					source=source.concat(cursor.getString("TEXT"));

				}
			}
			finally {
				cursor.close();
			}
			//System.out.println(source);
		}
		finally {
			cs.close();
		}
			
		
		PackageDependency.parse(new ANTLRInputStream(source),resolver ,owner,errListener);
 		//PackageDependency.parse(new ANTLRFileStream(args[0]),new ReferenceResolver());

	}
	
	public static void main(String args[])
	throws IOException,ClassNotFoundException , SQLException //, ParseException
	{
		/*Options options = new Options();
		options.addOption("d", true, "dbstring");
		
		
		CommandLineParser parser = new DefaultParser();
		CommandLine cmd = parser.parse( options, args);
		
		String dbstring = cmd.getOptionValue("d");
		if(dbstring == null ) {
			dbstring = "isgogndb:1521:isgogn";
		}*/
		
		/*Class.forName("oracle.jdbc.driver.OracleDriver");
		conn = DriverManager.getConnection("jdbc:oracle:thin:@"+dbstring, "ops$il01830", "il01830");*/
		conn = DriverManager.getConnection("jdbc:default:connection");
		conn.setAutoCommit(false);
		errListener = new DBLogErrorListener(conn);
		resolver = new DBRefResolver(conn);
		
		if( args.length == 3) {
			errListener.setParsingObject(args[0],args[1],args[2]);

			parse(args[0],args[1],args[2]);
		} else {
			ResultSet cursor;
			
			CallableStatement packs=conn.prepareCall("begin db_tools.pack_depend.get_unresolved_pacakges(?); end;");
			packs.registerOutParameter(1, OracleTypes.CURSOR);
			packs.execute();
			cursor = ((OracleCallableStatement)packs).getCursor(1);
			int i = 0;
			while (cursor.next () && i++ < 2000) {
				System.out.println(cursor.getString("OWNER")+"."+cursor.getString("OBJECT_NAME"));
				
				parse(cursor.getString("OWNER"),cursor.getString("OBJECT_NAME"),cursor.getString("OBJECT_TYPE"));
				conn.commit();

			}
			cursor.close();
		}
		
		conn.commit();
	}
}