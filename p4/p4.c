#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr,"usage: %s <name>\n",argv[0]);
        exit(1);
    }

    char* name = argv[1];
    size_t len = strlen(name);

    size_t sLen = len+3;  // ".s" + 0
    char* sName = (char*) malloc(sLen);
    if (sName == 0) {
        perror("malloc");
        exit(1);
    }

    strncpy(sName,name,sLen);
    strncat(sName,".s",sLen);

    size_t fLen = len+5; // ".fun" + 0
    char* fName = (char*) malloc(fLen);
    if (sName == 0) {
        perror("malloc");
        exit(1);
    }
    strncpy(fName,name,fLen);
    strncat(fName,".fun",fLen);

    printf("compiling %s to produce %s\n",fName,sName);

    FILE *f = fopen(sName,"w");
    if (f == 0) {
        perror(sName);
        exit(1);
    }

    fputs("    .data\n",f);
    fputs("format: .byte '%', 'd', 10, 0\n",f);
    fputs("    .text\n",f);
    fputs("    .global main\n",f);
    fputs("main:\n",f);
    fputs("    mov $0,%rax\n",f);
    fputs("    mov $format,%rdi\n",f);
    fputs("    mov $42,%rsi\n",f);
    fputs("    .extern printf\n",f);
    fputs("    call printf\n",f);
    fputs("    mov $0,%rax\n",f);
    fputs("    ret\n",f);

    fclose(f);

    size_t commandLen = len*2 + 1000;
    char* command = (char*) malloc(commandLen); 

    snprintf(command,commandLen,"gcc -o %s %s",name,sName);

    printf("compiling %s to produce %s\n",sName,name);
    printf("running %s\n",command);
    int rc = system(command);
    if (rc != 0) {
        perror(command);
        exit(1);
    }

    return 0;
}
