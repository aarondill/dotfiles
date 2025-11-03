#pragma once
#include <iostream>
#ifndef DEBUG
#define DEBUG 0
#endif
// Because reasons.
#define STRINGIFY1(x) #x
#define STRINGIFY(x) STRINGIFY1(x)
#define PLACE __FILE__ ":" STRINGIFY(__LINE__)

// Use implicit concatenation to reduce the number of strings in data
#define debug(x)                                                               \
  do {                                                                         \
    if (DEBUG) std::cerr << "(" PLACE "): " << x << std::endl;                 \
  } while (0)
#define debug2(x) debug("\n\t" #x " = " << x)
