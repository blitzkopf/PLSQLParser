import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.CallableStatement;
import java.sql.SQLException;
import oracle.jdbc.OracleTypes;

class DBRefResolver extends ReferenceResolver 
{
	Connection conn;
	PreparedStatement insProcInfo, insProcDep, delPack;
	CallableStatement findDBRef;
	public DBRefResolver(Connection conn )
	throws  SQLException
	{
		this.conn=conn;
		try {
			insProcInfo=conn.prepareStatement("begin db_tools.pack_depend.Register_Proc_Info(?,?,?,?,?,?,?); end; ");
			insProcDep=conn.prepareStatement("begin db_tools.pack_depend.Register_Proc_Dependency(?,?,?,?,?,?,?); end; ");
			delPack=conn.prepareStatement("begin db_tools.pack_depend.deregister_Package(?,?); end; ");
			findDBRef=conn.prepareCall("begin db_tools.pack_depend.find_ref(?,?,?,?,?,?,?); end; ");
			
		} catch(SQLException e) {
			//System.err.println(e);
			e.printStackTrace();
		}
		
		
	}

	public PLSQLElement findElement(String name,String currentSchema, String currentObject ) {
		PLSQLElement result = super.findElement(name,currentSchema,currentObject);
		//System.out.println("<- getting " + name);
		if(result == null ){
			
			try {
				findDBRef.setString(1,name);
				findDBRef.setString(2,currentSchema);
				findDBRef.setString(3,currentObject);
				findDBRef.registerOutParameter(4, java.sql.Types.VARCHAR);
				findDBRef.registerOutParameter(5, java.sql.Types.VARCHAR);
				findDBRef.registerOutParameter(6, java.sql.Types.VARCHAR);
				findDBRef.registerOutParameter(7, java.sql.Types.VARCHAR);
				findDBRef.execute();
				
				String refOwner= findDBRef.getString(4);
				String refName= findDBRef.getString(5);
				String refProcedure= findDBRef.getString(6);
				String refType= findDBRef.getString(7);

				//System.out.println(name + ":" + currentSchema+":"+currentObject);				
				//System.out.println(refOwner + ":" + refName+":"+refProcedure+":"+refType);
				
				if("PACKAGE".equals(refType) && refProcedure != null) {
					//System.out.println("Foxy");
					result=new PLSQLElement(refProcedure,"procedure","package",refOwner,refName);
				} else if(( "FUNCTION".equals(refType) || "PROCEDURE".equals(refType)) && refName != null) {
					//System.out.println("XXX!");
					result=new PLSQLElement(refOwner,"procedure","schema",refOwner,refName);
 				} else if("SCHEMA".equals(refType) && refOwner != null) {
					//System.out.println("Foxy!");
					result=new PLSQLElement(refOwner,"schema","db",refOwner,null);
				} else if(( "TABLE".equals(refType) || "VIEW".equals(refType))  && refOwner != null) {
					//System.out.println("Foxy!");
					result=new PLSQLElement(refOwner,"table","schema",refOwner,refName);
				}

				

				
			} catch(SQLException e) {
				//System.err.println(e);
				e.printStackTrace();
			}	
			
		}
		return result;
	}
	
	public void registerProcedureInfo(String owner,String objectName, String procName, String procType, 
		int beginLine, int endLine) 

	{
		try {
			insProcInfo.setString(1,owner);
			insProcInfo.setString(2,objectName);
			insProcInfo.setString(3,procName);
			insProcInfo.setInt(4,0);
			insProcInfo.setString(5,procType);
			insProcInfo.setInt(6,beginLine);
			insProcInfo.setInt(7,endLine);
			insProcInfo.execute();
		} catch(SQLException e) {
			//System.err.println(e);
			e.printStackTrace();
		}

		//System.out.println("// "+owner+"."+objectName+"."+procName+"["+beginLine+":"+endLine+"]");
	}
	
	public void registerReference(String owner,String objectName, String procName,
		String referencedOwner,String referencedObjectName, String referencedProcName, int lineNo)
	{	
		try {
			insProcDep.setString(1,owner);
			insProcDep.setString(2,objectName);
			insProcDep.setString(3,procName);
			insProcDep.setString(4,referencedOwner);
			insProcDep.setString(5,referencedObjectName);
			insProcDep.setString(6,referencedProcName);
			insProcDep.setInt(7,lineNo);
			insProcDep.execute();
		} catch(SQLException e) {
			//System.err.println(e);
			e.printStackTrace();
		}
		
		//System.out.println("\""+owner+"."+objectName+"."+procName+"\"->\""+referencedOwner+"."+referencedObjectName+"."+referencedProcName +"\"");
	}
	public void deregisterPackage(String owner,String objectName)
	{
		try {
			delPack.setString(1,owner);
			delPack.setString(2,objectName);
			delPack.execute();
		} catch(SQLException e) {
			//System.err.println(e);
			e.printStackTrace();
		}
	}

}