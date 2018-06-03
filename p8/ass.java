import java.io.*;
import java.util.*;

public class ass{
	public static void main(String[]args) throws IOException{ 
        String fileName = args[0];
		Scanner n = new Scanner(new File(fileName));
		ArrayList<String> words = new ArrayList<String>();
		words.add(n.nextLine());
		while(n.hasNext()){
			String word1 = n.nextLine();
			int first = Integer.parseInt(word1.charAt(0)+"", 16);
			if(first == 0)
				words.add("sub");
			else if(first == 8)
				words.add("movl");
			else if(first == 9)
				words.add("movh");
			else if(first == 14)
				words.add("jump");
			else if(first == 15)
				words.add("io");
			else{
				words.add(first+"?");
			}
			String word2 = n.nextLine();
			int second = Integer.parseInt(word1.charAt(1)+"", 16);
			int third = Integer.parseInt(word2.charAt(0)+"", 16);
			int fourth = Integer.parseInt(word2.charAt(1)+"", 16);

			words.add(second+"");
			if(first == 14){
				if(third == 0)
					words.add("jz");
				else if(third == 1)
					words.add("jnz");
				else if(third == 2)
					words.add("js");
				else if(third == 3)
					words.add("jns");
				else{
					words.add(third+"?");
				}
			}
			else if(first == 15){
				if(third == 0)
					words.add("ld");
				else if(third == 1)
					words.add("st");
				else{
					words.add(third+"?");
				}
			}
			else
				words.add(third+"");
			words.add(fourth+"");
		}
		int x = 0;
		int y = 0;
		while(x<words.size()){
			if(x == 0)
				System.out.println(words.get(x++));
			else{
				System.out.print((y)*2 +" " + words.get(x));
				x++;
                if(x>=words.size())
                    break;
				System.out.print(" "+words.get(x));
				x++;
                if(x>=words.size())
                    break;
				System.out.print(" "+words.get(x));
				x++;
                if(x>=words.size())
                    break;
				System.out.println(" "+words.get(x));
				x++;
                if(x>=words.size())
                    break;
		y++;
			}			
		}
	}
}
