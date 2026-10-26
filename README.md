# Rust + C++ in one project

Write functions in Rust, call them from C++, build everything with one command.

## Requirements
Rust (https://rustup.rs), CMake 3.20+, and a C++17 compiler.

## Build and run
    ./build.sh            # static: Rust is linked INTO the executable
    ./build.sh shared     # shared: Rust becomes a .so / .dylib / .dll

Windows: `cmake -S . -B build -DRUST_LINK_MODE=STATIC && cmake --build build --config Release`

## Daily workflow
1. Add a function to `rust/src/lib.rs`:

       #[no_mangle]
       pub extern "C" fn rs_square(x: i32) -> i32 { x * x }

2. Rebuild. `rustcore.h` is regenerated automatically.
3. Call `rs_square(4)` from C++ (`#include <rustcore.h>`).

## Use it in your own CMake project
    include(cmake/RustLibrary.cmake)
    add_rust_library(rustcore PATH rust)            # add SHARED for a DLL
    target_link_libraries(my_app PRIVATE rustcore)

## Layout
    CMakeLists.txt            top-level build, picks static or shared
    cmake/RustLibrary.cmake   add_rust_library(): runs cargo, wraps result as a CMake target
    rust/                     your Rust crate (Cargo.toml, build.rs, cbindgen.toml, src/lib.rs)
    app/main.cpp              C++ example using the library
    app/rustcore.hpp          optional RAII wrapper (no manual free calls)

## Rules of the boundary
- Export with `#[no_mangle] pub extern "C"`; use C-compatible types (ints, floats, pointers, `#[repr(C)]` structs).
- Memory allocated by Rust is freed by Rust (see `rs_string_free`), and vice versa.
- Panics abort (set in Cargo.toml) so they never unwind through C++.
- Windows + Debug + static: Rust links the release CRT; if you see CRT mismatch warnings, use Release.
