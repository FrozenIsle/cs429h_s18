import java.io.*;
import java.util.*;

public class disass{
	public static void main(String[]args) throws IOException{
		String fileName = args[0];
		Scanner n = new Scanner(new File(fileName));
		ArrayList<String> hexes = new ArrayList<String>();
		hexes.add("@0");
		while(n.hasNext()){
			Scanner n2 = new Scanner(n.nextLine());
			String word1 = n2.next();
			if(word1.equals("sub")){
				int rt = n2.nextInt();
				int ra = n2.nextInt();
				int rb = n2.nextInt();
				hexes.add("0" + Integer.toHexString(rt));
				hexes.add(Integer.toHexString(ra) + Integer.toHexString(rb));
			}
			else if(word1.charAt(0) == 'm'){
				byte i = n2.nextByte();
				String is = String.format("%02x", i);
//				System.out.println(is);
				String word1p = "8";
				int rt = n2.nextInt();
				if(word1.equals("movh"))
					word1p = "9";
				hexes.add(word1p + is.substring(0, 1));
				hexes.add(is.substring(1, 2) + Integer.toHexString(rt));
			}
			else if(word1.charAt(0) == 'j' || word1.equals("ld") || word1.equals("st")){
				int ra = n2.nextInt();
				String type = "0";
				if(word1.equals("jnz") || word1.equals("st"))
					type = "1";
				else if(word1.equals("js"))
					type = "2";
				else if(word1.equals("jns"))
					type = "3";
				int rt = n2.nextInt();
				String word1p = "e";
				if(word1.charAt(0) != 'j')
					word1p = "f";
				hexes.add(word1p + Integer.toHexString(ra));
				hexes.add(type + Integer.toHexString(rt));
			}
			else{
				System.out.println("ERROR");
			}
		}
		hexes.add("10");
		hexes.add("00");
		for(int x = 0;x<hexes.size();x++){
			System.out.println(hexes.get(x));		
		}
	}
}
