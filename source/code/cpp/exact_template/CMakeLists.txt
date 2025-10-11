:DELIMS tag = "{{ }}" stmt = "@!" comment = "%#"
cmake_minimum_required(VERSION 4.1)
project({{$ROOT}})


set(CMAKE_CXX_STANDARD 14)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# NOTE: must be *before* creating a target with add_executable
# Optimizing is needed to make the compiler recognize what should be warnings
add_compile_options(-O3 -Wall -Wextra -Wpedantic)

if (CMAKE_BUILD_TYPE MATCHES "Debug")
    add_compile_options(-Werror) # Make warnings to errors
    # -fsanitize=undefined enabling the detection of undefined behavior such as integer overflows,
    # -fsanitize=address enabling the detection of memory problems such as leaks.
    add_compile_options(-fsanitize=undefined -fsanitize=address)
    add_link_options(-fsanitize=undefined -fsanitize=address)
endif ()

file(GLOB MY_SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.cpp")
foreach (source_file ${MY_SOURCES})
    message("Found source file: ${source_file}")
endforeach ()

add_executable(main ${MY_SOURCES})
