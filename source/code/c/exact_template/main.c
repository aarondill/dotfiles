#include <stdio.h>
int main(int argc, char *argv[]) {
  // All paths are relative to the source root unless specified otherwise.
  printf("FILENAME: ${FILENAME}\n"); // This file's name
  printf("FILEPATH: ${FILEPATH}\n"); // This file's path
  printf("DIRNAME: ${DIRNAME}\n");   // This file's directory name
  printf("REALPATH: ${REALPATH}\n"); // This file's absolute path
  printf("DATE: ${DATE}\n");         // The current date mm/dd/yyyy
  printf("TIME: ${TIME}\n");         // The current time hh:mm 24hr

  printf("Hello, World!\n");
  return 0;
}
