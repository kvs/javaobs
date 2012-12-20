import java.io.*;
import java.util.Date;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

public class Test2 implements Serializable
{
    Map<String, Integer> map;
    public void setMap(Map<String, Integer> m) { map = m; }
    
    public static void main(String args[])
    {
        Test2 t = new Test2();
        t.map = new HashMap<String, Integer>();
        t.map.put("One", new Integer(1));
        t.map.put("Two", new Integer(2));
        t.map.put("Three", new Integer(3));
        t.map.put("Four", new Integer(4));
        t.map.put("Five", new Integer(5));
        t.map.put("Six", new Integer(6));
        t.map.put("Seven", new Integer(7));
        
        try
        {
            FileOutputStream fos = new FileOutputStream("t2.tmp");
            ObjectOutputStream oos = new ObjectOutputStream(fos);
            
            oos.writeObject(t);
            oos.close();
        }

        catch (Throwable x)
        {
            System.err.println(x);
        }

        System.exit(0);
    }
}
