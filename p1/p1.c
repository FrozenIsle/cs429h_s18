#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <limits.h>
#define MISSING() printf("missing %s:%d\n",__FILE__,__LINE__)
typedef enum {false, true} bool;
int main(int argc, char* argv[]) {

    for (int i=1; i<argc; i++) {
        long n = atoll(argv[i]);
	n++;
	long a = 0;
	long b = 0;
	long x = -1;
	long y = -1;
	long root = (long)sqrt(n);
	long remain = n - pow(root, 2);
	a = root - 1;
	if(remain == 0){
		x = a;
		y = b;
	}
	else if(remain <= root + 1){
		a++;
		remain--;
		b += remain;
	}
	else{
		a++;
		b += root;
		remain -= root + 1;
		a -= remain;
	}
	if(root % 2 == 0){
		x = b;
		y = a;
	}
	else{
		x = a;
		y = b;
	}
	n--;
        printf("%ld (%ld,%ld)\n",n,x,y);
            
    }
    return 0;
}
