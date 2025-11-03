:DELIMS tag = "{{ }}" stmt = "@!" comment = "%#"
#include "debug.h"
#include <iostream>
int main() {
  debug("Hello, World from " << "{{$ROOT}}");
  return 0;
}
