#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>

#if     defined(__linux__)
#define __USE_XOPEN
#endif

#include <math.h>

//  written by Chris.McDonald@uwa.edu.au, August 2015
//
//  compile:  cc -std=c99 -Wall -Werror -o haversine haversine.c -lm
//  run:      ./haversine -31.977537 115.816509 -31.982831 115.818898

//  cf:       https://en.wikipedia.org/wiki/Haversine_formula

#define EARTH_RADIUS_IN_METRES          6372797

static double degrees_to_radians(double degrees)
{
    return (degrees * M_PI / 180.0);
}

static double haversine(double lat1, double lon1, double lat2, double lon2)
{
    double deltalat = (lat2 - lat1) / 2.0;
    double deltalon = (lon2 - lon1) / 2.0;

    double sin1     = sin( degrees_to_radians(deltalat) );
    double cos1     = cos( degrees_to_radians(lat1) );
    double cos2     = cos( degrees_to_radians(lat2) );
    double sin2     = sin( degrees_to_radians(deltalon) );

    double x        = sin1*sin1 + cos1*cos2 * sin2*sin2;
    double metres   = 2 * EARTH_RADIUS_IN_METRES * asin( sqrt(x) );
    return metres;
}

static bool valid_location(double latitude, double longitude)
{
    return (latitude  >= -90.0  && latitude  <= 90.0   &&
            longitude >= -180.0 && longitude <= 180.0);
}

int main(int argc, char *argv[])
{
    int result;

//  CHECK THE NUMBER OF ARGUMENTS
    if(argc != 5)
    {
        fprintf(stderr, "Usage: %s lat1 lon1 lat2 lon2\n", argv[0]);
        result  = EXIT_FAILURE;
    }
    else
    {
//  CONVERT EACH COMMAND-LINE ARGUMENT TO A FLOATING-POINT NUMBER
        double lat1 = atof(argv[1]);
        double lon1 = atof(argv[2]);

        double lat2 = atof(argv[3]);
        double lon2 = atof(argv[4]);

//  ENSURE THAT THE 2 PROVIDED LOCATIONS ARE EACH VALID
        if(valid_location(lat1, lon1) == false)
        {
            fprintf(stderr, "%s: location 1 is invalid!\n", argv[0]);
            result = EXIT_FAILURE;
        }
        else if(valid_location(lat2, lon2) == false)
        {
            fprintf(stderr, "%s: location 2 is invalid!\n", argv[0]);
            result = EXIT_FAILURE;
        }
//  ALL GOOD - CALCULATE AND PRINT DISTANCE BETWEEN LOCATIONS
        else
        {
            printf("%i\n", (int)haversine(lat1, lon1, lat2, lon2));
            result = EXIT_SUCCESS;
        }
    }
    return result;
}
