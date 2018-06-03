#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <unistd.h>

#include "matrix.h"

int matrix[N][N];

double getFrequencyGHz() {
    int rc = system("cat /proc/cpuinfo | grep 'model name' | sed -e 's/.* @ //' > freq.txt");
    if (rc != 0) {
        perror("system");
        exit(-1);
    }

    /* open freq.txt */
    FILE *file = fopen("freq.txt","r");
    if (file == 0) {
        perror("open freq.txt");
        exit(-1);
    }

    /* read frequency from freq.txt */
    double freqGHz = 0;
    rc = fscanf(file,"%lf",&freqGHz);
    if (rc != 1) {
        perror("scanning file");
        exit(-1);
    }
    fclose(file);

    return freqGHz;
}

#define T 6

void report(uint64_t count, double cycleNS, int latency) {
    double nsPerThing = (T * 1e9) / count;
    double cyclesPerThing = nsPerThing / cycleNS;

    if (latency) {
        printf("    latency: %f ns %f cycles\n",nsPerThing,cyclesPerThing);
    } else {
        printf("    throughput: %f/ns %f/cycle\n",1/nsPerThing,1/cyclesPerThing);
    }
}

volatile int done = 0;

void handler() {
    done = 1;
}

/* run one test */
void one(char* what, long (*func)(), double cycleNS, int latency) {
    uint64_t count = 0;

    done = 0;
    printf("%s ...\n",what);
    signal(SIGALRM,handler);
    alarm(T);
    
    while (!done) {
        count += func();
    }

    report(count,cycleNS,latency);
}


extern long indepAdds();
extern long depAdds();

extern long indepMuls();
extern long depMuls();

extern long indepDivs();
extern long depDivs();

extern long indepLoads();
extern long depLoads();

extern long nops();

int main(int argc, char* argv[]) {
    double freqGHz = getFrequencyGHz();
    double cycleNS = 1 / freqGHz;

    printf("freq = %fGHz, cycle_time = %fns\n",freqGHz,cycleNS);

    one("independent add instructions",indepAdds, cycleNS, 0);
    one("dependent add instructions",depAdds, cycleNS, 1);

    one("independent loads instructions",indepLoads, cycleNS, 0);
    one("dependent load instructions",depLoads, cycleNS, 1);

    one("independent multiply instrutions",indepMuls, cycleNS, 0);
    one("dependent multiply instrutions",depMuls, cycleNS, 1);

    one("independent divide instructions",indepDivs, cycleNS, 0);
    one("dependent divide instructions",depDivs, cycleNS, 1);

    one("decode",nops, cycleNS, 0);

    int c1 = 0;
    for (int i=0; i<N; i++) {
        for (int j=i+1; j<N; j++) {
            int b = rand() & 1;
            int x = rand();
            int y = b ? x : x+1;
            matrix[i][j] = x;
            matrix[j][i] = y;
            c1 += b;
        }
    }

    printf("matrix balance (per comparison) ...\n");

    signal(SIGALRM,handler);
    uint64_t count = 0;
    done = 0;

    alarm(T);

    while (!done) {
        int c2 = balance();
        count ++;
        if (c1 != c2) {
            printf("expected=%d found=%d\n",c1,c2);
            break;
        }
    }

    report((((N * N) - N) / 2) * count, cycleNS, 1);

    return 0;
}
