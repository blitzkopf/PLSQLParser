import java.util.Hashtable;
import java.util.ArrayDeque;
import java.util.Iterator;

class PLSQLElement
{	
	public String name;
	public String type;
	public String ctxType;
	public String objectOwner;
	public String objectName;
	
	public  PLSQLElement(String elementName,String elemenType,String ctxType,
		String objectOwner ,String objectName ) 
	{
		name=elementName;
		type=elemenType;
		this.ctxType=ctxType;
		this.objectOwner = objectOwner;
		this.objectName = objectName;
	}
	
	public  PLSQLElement(String elementName,String elemenType,String ctxType)
	{
		this(elementName, elemenType, ctxType,null,null);
	}
}

class DefinitionScope extends Hashtable<String,PLSQLElement> 
{
	String name;
	String type;
	public DefinitionScope(String name, String type) 
	{
		super();
		this.name=name;
		this.type=type;

	}
}

public class ReferenceResolver 
{
	ArrayDeque<DefinitionScope> scopeStack= new ArrayDeque<DefinitionScope>();
	DefinitionScope itemMap;
	
	public void registerElement(String name,String type)
	{
		//System.out.println("-> putting " + name);
		itemMap.put(name,new PLSQLElement(name,type,itemMap.type));
	}

	public PLSQLElement findElement(String name, String currentSchema,String currentObject) {
		PLSQLElement result;
		//System.out.println("<- getting " + name);
		for (Iterator<DefinitionScope> it = scopeStack.descendingIterator(); it.hasNext(); ) {
    		DefinitionScope map = it.next();
    		result = map.get(name);
    		if(result != null ) {
    			return result;
    		}
    	}
		return null;
	}

	public void pushScope(String name,String type) {
		//System.out.println("push "+name+ " + " +type);
		itemMap=new DefinitionScope(name,type);
		scopeStack.push(itemMap);

	}

	public void popScope() {
		//System.out.println("pop");
		scopeStack.pop();
	}

	public void registerProcedureInfo(String owner,String objectName, String procName, String procType, 
		int beginLine, int endLine) 
	{
		//System.out.println("// "+owner+"."+objectName+"."+procName+"["+beginLine+":"+endLine+"]");
	}
	
	public void registerReference(String owner,String objectName, String procName,
		String referencedOwner,String referencedObjectName, String referencedProcName, int lineNo)
	{
		System.out.println("\""+owner+"."+objectName+"."+procName+"\"->\""+referencedOwner+"."+referencedObjectName+"."+referencedProcName +"\"");
	}
	public void deregisterPackage(String owner,String objectName)
	{
		
	}
	
};