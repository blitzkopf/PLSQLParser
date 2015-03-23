import java.util.Hashtable;
import java.util.ArrayDeque;
import java.util.Iterator;

class PLSQLElement
{	
	public String name;
	public String type;
	public String ctxType;
	public  PLSQLElement(String elementName,String elemenType,String ctxType) 
	{
		name=elementName;
		type=elemenType;
		this.ctxType=ctxType;
	}
}

class DefinitionContext extends Hashtable<String,PLSQLElement> 
{
	String name;
	String type;
	public DefinitionContext(String name, String type) 
	{
		super();
		this.name=name;
		this.type=type;

	}
}

public class ReferenceResolver 
{
	ArrayDeque<DefinitionContext> ctxStack= new ArrayDeque<DefinitionContext>();
	DefinitionContext itemMap;
	public void registerElement(String name,String type)
	{
		System.out.println("-> putting " + name);
		itemMap.put(name,new PLSQLElement(name,type,itemMap.type));
	}

	public PLSQLElement findElement(String name) {
		PLSQLElement result;
		System.out.println("<- getting " + name);
		for (Iterator<DefinitionContext> it = ctxStack.descendingIterator(); it.hasNext(); ) {
    		DefinitionContext map = it.next();
    		result = map.get(name);
    		if(result != null ) {
    			return result;
    		}
    	}
		return null;
	}

	public void pushContext(String name,String type) {
		System.out.println("push "+name+ " + " +type);
		itemMap=new DefinitionContext(name,type);
		ctxStack.push(itemMap);

	}

	public void popContext() {
		//System.out.println("pop");
		ctxStack.pop();
	}

};