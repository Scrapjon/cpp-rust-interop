cmake_minimum_required(VERSION 3.20)
project(rust_cpp_demo LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# STATIC (default): Rust is linked into the executable. One file, no DLL.
# SHARED          : Rust becomes a .dll/.so/.dylib next to the executable.
set(RUST_LINK_MODE "STATIC" CACHE STRING "How to link the Rust code: STATIC or SHARED")
set_property(CACHE RUST_LINK_MODE PROPERTY STRINGS STATIC SHARED)

include(cmake/RustLibrary.cmake)

if(RUST_LINK_MODE STREQUAL "SHARED")
    add_rust_library(rustcore PATH rust SHARED)
else()
    add_rust_library(rustcore PATH rust)
endif()

add_executable(app app/main.cpp)
target_link_libraries(app PRIVATE rustcore)      # <-- this is all C++ needs

# Windows only: a DLL must sit beside the .exe to be found at runtime.
if(WIN32 AND RUST_LINK_MODE STREQUAL "SHARED")
    add_custom_command(TARGET app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:rustcore> $<TARGET_FILE_DIR:app>)
endif()
