#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>

#include "parabola-ekf.h"

#define XVARIANCE 2.0
#define YVARIANCE 2.0

#define NFIELDS 3

const double dt = 0.1;

void setupEKF(ekf_t * ekf_p){
  ekf_init(ekf_p, Nsta, Mobs);

  // set initial state:
  // at origin with zero velocity
  ekf_p->x[0] = 0;
  ekf_p->x[1] = 0;
  ekf_p->x[2] = 0;
  ekf_p->x[3] = 0;
  
  // some uncertainty in acceleration
  double sigma_a = 0.1;

  // prediction uncertainty:
  ekf_p->P[0][0] = 10;
  ekf_p->P[1][1] = 10;
  ekf_p->P[2][2] = 10;
  ekf_p->P[3][3] = 10;

  // process noise covariance
  // uncertainty here mostly comes from integration error
  // and uncertainty in acceleration (g)
  ekf_p->Q[0][0] = 0.5 * sigma_a * dt * dt;
  ekf_p->Q[1][1] = 0.5 * sigma_a * dt * dt;
  ekf_p->Q[2][2] = sigma_a * dt;
  ekf_p->Q[3][3] = sigma_a * dt;

  // sensor noise variance
  ekf_p->R[0][0] = XVARIANCE;
  ekf_p->R[1][1] = YVARIANCE;
  
}

int nansInEKFState(double state[Nsta]){
  for(int i = 0; i < Nsta; i++){
    if(isnan(state[i])) {
      return 1;
    }
  }
  return 0;
}

/*
  - Read in a list of measurements
  - Kalman filter them
  - Print out estimated state at each step
*/

int readCSVnumbersFrom(char * line, int numFields, double * numbers) {
  char * next = line;
  char * endOfNumber;
  int n = 0;
  for(n = 0; (n < numFields && next[0] != 0); n++){
    numbers[n] = strtod(next, &endOfNumber);
    next = endOfNumber + 1; // skip over trailing comma
  }
  return n+1;
}

ekf_t ekf;

int main(int argc, char ** argv){
  
  char * measurementFile = "test.csv";
  char * outputFileName = NULL;
  FILE * outputFile;
  int verbose = 0;
  int c;
  opterr = 0;
  
  while ((c = getopt (argc, argv, "vi:o:")) != -1){
    switch (c) {
      case 'v':
        verbose = 1;
        break;
      case 'i':
        measurementFile = optarg;
        break;
      case 'o':
        outputFileName = optarg;
        break;
      case '?':
        if (optopt == 'c')
          fprintf (stderr, "Option -%c requires an argument.\n", optopt);
        else if (isprint (optopt))
          fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        else
          fprintf (stderr,
                   "Unknown option character `\\x%x'.\n",
                   optopt);
        return 1;
      default:
        abort ();
    }
  }
  
  if(outputFileName!=NULL){
    outputFile = fopen(outputFileName, "w");
  }
  

  // file reading code adapted from https://stackoverflow.com/a/3501681
  FILE * fp;
  char * line = NULL;
  size_t len = 0;
  ssize_t read;


  fp = fopen(measurementFile, "r");
  if (fp == NULL) {
    printf("Unable to open %s!\n", measurementFile);
    exit(EXIT_FAILURE);
  }

  double fields[NFIELDS];
  
  int calls = 0;
  setupEKF(&ekf);

  // skip first line
  read = getline(&line, &len, fp);
  // read file line by line
  while ((read = getline(&line, &len, fp)) != -1) {
    if(verbose) printf("Read:         %s", line);
    
    char prediction[200];
    snprintf(prediction, 200, "%.2lf, %.2lf, %.2lf, %.2lf, %.2lf,    %.4lf, %.4lf, %.4lf, %.4lf", 
        fields[0] + dt,
        ekf.x[0], ekf.x[1], ekf.x[2], ekf.x[3],
        ekf.P[0][0], ekf.P[1][1], ekf.P[2][2], ekf.P[3][3]);
    
    if(outputFileName!=NULL) fprintf(outputFile, "%s\n", prediction);
    if(verbose) printf("Est. state:  %s\n\n", prediction);

    int fieldsRead = readCSVnumbersFrom(line, NFIELDS, fields);
    
    if(fieldsRead<1){
      continue;
    }

    //printf("  1: %lf\n", fields[0]);
    //printf("  2: %lf\n", fields[1]);
    //printf("  3: %lf\n", fields[2]);

    double dt = 0.1;
    double observations[2];
    observations[0] = fields[1];
    observations[1] = fields[2];
    
    // fill in EKF state and state transition info
    model(ekf.x, ekf.fx, ekf.F, ekf.hx, ekf.H, dt);

    // Send these measurements to the EKF
    if( ekf_step(&ekf, observations) != 0){
      printf("Step error after %d filter calls!\n",calls);
      setupEKF(&ekf);
      calls = 0;
    }else if(nansInEKFState(ekf.x)){
      printf("Found NaN in EKF state after %d calls! Resetting\n",calls);
      setupEKF(&ekf);
      calls = 0;
    }else{
      calls++;
    }
  }

  if(outputFileName!=NULL){
    fclose(outputFile);
  }

  fclose(fp);
  if (line) {
    free(line);
  }
  exit(EXIT_SUCCESS);


}
