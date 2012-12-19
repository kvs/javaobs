import java.io.*;
import java.util.Date;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

public class Test implements Serializable
{
    int a;
    int b;
    long c;
    String d;
    int e[];
    Date date;
    Map map;
    

    public void setA(int x) { a = x; }
    public void setB(int x) { b = x; }
    public void setC(long l) { c = l; }
    public void setD(String s) { d = s; }
    public void setE(int x[]) { e = x; }
    public void setDate(Date d) { date = d; }
    public void setMap(Map m) { map = m; }
    
    public static void main(String args[])
    {
        Test t = new Test();
        t.setA(1);
        t.setB(2);
        t.setC(1000000000000000L);
        t.setD("Hello");
        int a[] = new int[20];
        for (int i = 0; i < 20; i++) 
        {
            a[i] = i;
        }
        
        t.setE(a);
        Calendar cal = Calendar.getInstance();
        cal.set(2006, 5, 5, 13, 20, 00);
        cal.set(Calendar.MILLISECOND, 0);
        t.setDate(cal.getTime());
        
        try
        {
            FileOutputStream fos = new FileOutputStream("t.tmp");
            ObjectOutputStream oos = new ObjectOutputStream(fos);
            
            oos.writeObject(t);
            oos.writeObject(new Date());
            oos.close();
        }

        catch (Throwable x)
        {
            System.err.println(x);
        }

        System.exit(0);
    }
}
