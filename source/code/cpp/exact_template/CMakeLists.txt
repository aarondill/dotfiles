:DELIMS tag = "{{ }}" stmt = "@!" comment = "%#"
cmake_minimum_required(VERSION 4.1)
project({{$ROOT}})


set(CMAKE_CXX_STANDARD 14)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # NOTE: must be *before* creating a target with add_executable
    # Optimizing is needed to make the compiler recognize what should be warnings
    add_compile_options(-O3 -Wall -Wextra -Wpedantic -Wno-changes-meaning)

    if (CMAKE_BUILD_TYPE MATCHES "Debug")
        # Make warnings to errors
        add_compile_options(-Werror -Wno-error=unused-variable -Wno-error=unused-function -Wno-error=unused-value)
        # -fsanitize=undefined enabling the detection of undefined behavior such as integer overflows,
        # -fsanitize=address enabling the detection of memory problems such as buffer overflows and memory leaks
        add_compile_options(-fsanitize=undefined,address)
        add_link_options(-fsanitize=undefined,address)
    endif ()
else ()
    message("This makefile only sets flags for gcc. Please submit a pull request to modify this if necessary.")
endif ()

file(GLOB SOURCES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.cpp")
foreach (source_file ${SOURCES})
    message("Found source file: ${source_file}")
endforeach ()
file(GLOB HEADERS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.h" "*.hpp")
foreach (header ${HEADERS})
    message("Found header file: ${header}")
endforeach ()

add_executable(main ${SOURCES} ${HEADERS})
