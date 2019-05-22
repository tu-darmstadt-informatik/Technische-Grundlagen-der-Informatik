
public class tgdip {
	
	public static int[] matrix = {3, 4, 5, 9, 4, 9, 1, 2, 2};
	public static int matrixsize = 3;
	
	public int[] calcnewmatrix(int pos, int size, int[] matrix)
	{
		int[] newmatrix = new int[(size-1)*(size-1)];
		
		for(int i=1; i < size;i++) //rows -> i*(size) -> start from row 1!
		{
			for(int j=0; j < size;j++) //lines -> j*1
			{
				int rowval = i*(size);
				int lineval = j; //verschiebung um 1 nach rechts!
				
				if(lineval != pos) //skip pos
				{
					int newrowval  = (i-1)*(size-1); //wird um 1 kleiner
					int newlineval = j;
					
					if(newlineval > pos) //correct actpos after skip pos
					{
						newlineval -= 1;
					}
							  
					newmatrix[newrowval + newlineval] = matrix[rowval+lineval];
				}
			}
		}
		
		return newmatrix;
	}
	
	public int calcdet(int size, int[] matrix)
	{
		//anchor
		if(size <= 1)
		{
			return matrix[0];
		}	
		
		int result = 0;
		
		for(int i=0; i<size; i++) //count line
		{
			result += Math.pow(-1, i) * matrix[i] * calcdet(size-1,calcnewmatrix(i,size,matrix));
		}
		
		return result;
	}
	
	public static void main(final String[] args)
	{
		tgdip t = new tgdip();
		
		System.out.println(t.calcdet(matrixsize,matrix));
	}

}
