#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include "matrix.h"




int balance(){
	int count = 0;
	int bsize = 400;
	if(N < bsize)
		bsize = N;
	int cache[bsize-1][(bsize-1)*2];
	int cache2[bsize][bsize*2];
	int cut = N % bsize;
	int msize = N - cut;
	int bdim = msize/bsize;

	for(int x = 0;x<bdim;x++)
		for(int y = x;y<bdim;y++){
		int xstart = x*bsize;
		int ystart = y*bsize;

		if(x == y){
			for(int i = 0;i<bsize;i++){
				for(int j = 0; j<i; j++){
					cache[j][(i-j - 1)*2 +1] = matrix[i+xstart][j+ystart];
				}
				for(int j = i+1;j<bsize;j++){
					cache[i][(j-i - 1)*2] = matrix[i+xstart][j+ystart];
				}
			}

			for(int i = 0; i<bsize-1; i++)
				for(int j = 0;j< (bsize-i-1)*2;j+=2)
					count += cache[i][j] == cache[i][j+1];
				;
		}		
		else{

			for(int i = 0;i<bsize;i++){
				for(int j = 0; j<bsize; j++){
					cache2[i][j*2] = matrix[i+xstart][j+ystart];
				}
				for(int j = 0;j<bsize;j++){
					cache2[j][i*2+1] = matrix[i+ystart][j+xstart];
				}
			}

			for(int i = 0; i<bsize; i++)
				for(int j = 0;j< bsize*2;j+=2)
					count += cache2[i][j] == cache2[i][j+1];
				;
		}
		}

	for(int i = 0;i<cut;i++)
		for(int j = 0;j<N-1-i;j++)
			count += matrix[N-1-i][j] == matrix[j][N-1-i];

	return count;

}

