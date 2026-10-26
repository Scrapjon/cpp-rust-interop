# RustLibrary.cmake
#
#   add_rust_library(<target> PATH <crate dir> [SHARED])
#
# Builds the Rust crate with cargo and exposes it as a normal CMake target:
#
#   target_link_libraries(my_app PRIVATE <target>)
#
# That one line gives my_app: the include path to the generated header,
# the library to link, and the right system libraries. Default is STATIC.

find_program(CARGO_EXECUTABLE cargo REQUIRED
    HINTS "$ENV{HOME}/.cargo/bin" "$ENV{USERPROFILE}/.cargo/bin")

function(add_rust_library target)
    cmake_parse_arguments(ARG "SHARED" "PATH" "" ${ARGN})
    if(NOT ARG_PATH)
        message(FATAL_ERROR "add_rust_library: PATH <crate dir> is required")
    endif()
    get_filename_component(crate_dir "${ARG_PATH}" ABSOLUTE)

    # The crate's package name decides the output file names.
    file(READ "${crate_dir}/Cargo.toml" manifest)
    string(REGEX MATCH "name[ ]*=[ ]*\"([A-Za-z0-9_-]+)\"" _ "${manifest}")
    string(REPLACE "-" "_" crate_name "${CMAKE_MATCH_1}")

    set(cargo_target_dir "${CMAKE_BINARY_DIR}/cargo")
    set(header_dir       "${CMAKE_BINARY_DIR}/rust_include")
    file(MAKE_DIRECTORY "${header_dir}")

    # Debug config -> cargo "debug" profile, everything else -> "release".
    set(profile_dir "$<IF:$<CONFIG:Debug>,debug,release>")
    set(profile_arg "$<IF:$<CONFIG:Debug>,,--release>")

    if(ARG_SHARED)
        set(kind SHARED)
        if(WIN32)
            set(lib_file    "${crate_name}.dll")
            set(implib_file "${crate_name}.dll.lib")
        elseif(APPLE)
            set(lib_file "lib${crate_name}.dylib")
        else()
            set(lib_file "lib${crate_name}.so")
        endif()
    else()
        set(kind STATIC)
        if(WIN32)
            set(lib_file "${crate_name}.lib")
        else()
            set(lib_file "lib${crate_name}.a")
        endif()
    endif()
    set(lib_path "${cargo_target_dir}/${profile_dir}/${lib_file}")
    set(debug_lib   "${cargo_target_dir}/debug/${lib_file}")
    set(release_lib "${cargo_target_dir}/release/${lib_file}")

    # 1. Run cargo on every build (it is a no-op when nothing changed).
    add_custom_target(${target}_cargo ALL
        COMMAND ${CMAKE_COMMAND} -E env "RUST_HEADER_DIR=${header_dir}"
                ${CARGO_EXECUTABLE} build ${profile_arg}
                --manifest-path "${crate_dir}/Cargo.toml"
                --target-dir "${cargo_target_dir}"
        BYPRODUCTS "${lib_path}" "${header_dir}/${crate_name}.h"
        COMMENT "Building Rust crate '${crate_name}' with cargo"
        USES_TERMINAL)

    # 2. Wrap the result as an imported target.
    add_library(${target} ${kind} IMPORTED GLOBAL)
    # Per-config locations (works with Makefiles, Ninja and Visual Studio).
    # RelWithDebInfo / MinSizeRel fall back to the Release build.
    set_target_properties(${target} PROPERTIES
        IMPORTED_CONFIGURATIONS "DEBUG;RELEASE"
        IMPORTED_LOCATION_DEBUG   "${debug_lib}"
        IMPORTED_LOCATION_RELEASE "${release_lib}"
        MAP_IMPORTED_CONFIG_RELWITHDEBINFO RELEASE
        MAP_IMPORTED_CONFIG_MINSIZEREL RELEASE
        INTERFACE_INCLUDE_DIRECTORIES "${header_dir}")
    if(ARG_SHARED AND WIN32)
        set_target_properties(${target} PROPERTIES
            IMPORTED_IMPLIB_DEBUG   "${cargo_target_dir}/debug/${implib_file}"
            IMPORTED_IMPLIB_RELEASE "${cargo_target_dir}/release/${implib_file}")
    endif()
    add_dependencies(${target} ${target}_cargo)

    # 3. A static Rust lib contains Rust's runtime, which needs a few OS libs.
    if(NOT ARG_SHARED)
        if(WIN32)
            set(sys_libs ws2_32 userenv bcrypt ntdll advapi32 kernel32)
        elseif(APPLE)
            set(sys_libs System)
        else()
            set(sys_libs pthread dl m)
        endif()
        set_property(TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES "${sys_libs}")
    endif()
endfunction()
