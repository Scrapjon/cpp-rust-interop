// Runs automatically every time `cargo build` runs.
// It reads src/lib.rs and writes a C header, so you never write headers by hand.
use std::{env, path::PathBuf};

fn main() {
    let crate_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());

    // CMake tells us where to put the header; default to ./include for plain `cargo build`.
    let out_dir = env::var("RUST_HEADER_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| crate_dir.join("include"));
    std::fs::create_dir_all(&out_dir).unwrap();

    match cbindgen::generate(&crate_dir) {
        Ok(bindings) => {
            bindings.write_to_file(out_dir.join("rustcore.h"));
        }
        Err(e) => panic!("cbindgen failed: {e}"),
    }

    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-env-changed=RUST_HEADER_DIR");
}
