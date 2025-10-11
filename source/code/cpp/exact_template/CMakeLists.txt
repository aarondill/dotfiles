cmake_minimum_required(VERSION 4.1)
project(untitled)

file(GLOB MY_SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.cpp")

# Print the list of found source files
foreach (source_file ${MY_SOURCES})
    message("Found source file: ${source_file}")
endforeach ()

set(CMAKE_CXX_STANDARD 14)

# NOTE: must be *before* creating a target with add_executable
add_compile_options(-O3 -Wall -Wextra -Wpedantic -Werror)

if (CMAKE_BUILD_TYPE MATCHES "Debug")
    # -fsanitize=undefined enabling the detection of undefined behavior such as integer overflows,
    # -fsanitize=address enabling the detection of memory problems such as leaks.
    add_compile_options(-fsanitize=undefined -fsanitize=address)
    add_link_options(-fsanitize=undefined -fsanitize=address)
endif ()

add_executable(untitled ${MY_SOURCES})
