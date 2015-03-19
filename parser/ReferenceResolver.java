import java.util.Hashtable;


class PLSQLElement
{	
	public String name;
	public String type;
	public  PLSQLElement(String elementName,String elemenType) 
	{
		name=elementName;
		type=elemenType;
	}
}

public class ReferenceResolver 
{
	Hashtable<String,PLSQLElement> itemMap=new Hashtable<String,PLSQLElement>();
	public void registerElement(String name,String type)
	{
		System.out.println("-> putting " + name);
		itemMap.put(name,new PLSQLElement(name,type));
	}

	public PLSQLElement findElement(String name) {
		System.out.println("<- getting " + name);
		return itemMap.get(name);
	}

	public void pushContext(String name,String type) {
		System.out.println("push");

	}

	public void popContext() {
		System.out.println("pop");
	}

};