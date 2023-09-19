/*
 * Author:  Aaron Dill
 * Date:    ${DATE}
 */
#include <stdio.h>
int main(int argc, char *argv[]) {
  // All paths are relative to the source root unless specified otherwise.
  printf("FILEPATH: ${FILEPATH}\n");   // This file's path
  printf("REALPATH: ${REALPATH}\n");   // This file's absolute path
  printf("FILENAME: ${FILENAME}\n");   // This file's name
  printf("DIRNAME: ${DIRNAME}\n");     // This file's directory name
  printf("DATE: ${DATE}\n");           // The current date mm/dd/yyyy
  printf("TIME: ${TIME}\n");           // The current time hh:mm 24hr
  printf("EXTENSION: ${EXTENSION}\n"); // This file's extension (last!)
  printf("BASENAME: ${BASENAME}\n");   // This file's name without extension
  printf("ROOT: ${ROOT}\n");           // The name of root (project)

  printf("Hello, World!\n");
  return 0;
}
