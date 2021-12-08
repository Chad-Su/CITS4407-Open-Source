#include  "calcmarks.h"

// calcmarks, version 7, released Fri May 29 11:26:26 AWST 2020

int main(int argc, char *argv[])
{
    int nmarks = 0;

    if(argc == 1) {
         nmarks += readmarks(stdin);
    }
    else {
        for(int a=1 ; a<argc ; ++a) {
            FILE *fp = fopen(argv[a], "r");

            if(fp == NULL) {
                fprintf(stderr, "Cannot open %s\n", argv[a]);
                exit(EXIT_FAILURE);
            }
            nmarks += readmarks(fp);
	    fclose(fp);
        }
    }
    correlation(nmarks);
    return(0);
}
