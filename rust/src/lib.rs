//! The Rust side. Everything marked `#[no_mangle] pub extern "C"` becomes
//! callable from C++. Add your own functions below and rebuild: the C++
//! header is regenerated automatically.

use std::ffi::{c_char, c_void, CStr, CString};

// ---------------------------------------------------------------------------
// 1. Plain values: the simplest case.
// ---------------------------------------------------------------------------

/// Adds two numbers.
#[no_mangle]
pub extern "C" fn rs_add(a: i32, b: i32) -> i32 {
    a + b
}

// ---------------------------------------------------------------------------
// 2. Arrays: pass pointer + length, rebuild a safe slice on the Rust side.
// ---------------------------------------------------------------------------

/// Sums `len` doubles starting at `data`.
///
/// # Safety
/// `data` must point to `len` valid doubles (or be null with len == 0).
#[no_mangle]
pub unsafe extern "C" fn rs_sum(data: *const f64, len: usize) -> f64 {
    if data.is_null() {
        return 0.0;
    }
    std::slice::from_raw_parts(data, len).iter().sum()
}

// ---------------------------------------------------------------------------
// 3. Strings: Rust allocates, so Rust must free. Never `free()` it from C++.
// ---------------------------------------------------------------------------

/// Returns a newly allocated greeting. Release it with `rs_string_free`.
///
/// # Safety
/// `name` must be null or a valid NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn rs_greet(name: *const c_char) -> *mut c_char {
    let name = if name.is_null() {
        "stranger".into()
    } else {
        CStr::from_ptr(name).to_string_lossy()
    };
    CString::new(format!("Hello, {name}! (from Rust)"))
        .unwrap()
        .into_raw()
}

/// Frees a string returned by this library.
///
/// # Safety
/// `s` must come from this library and must not be freed twice.
#[no_mangle]
pub unsafe extern "C" fn rs_string_free(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}

// ---------------------------------------------------------------------------
// 4. Objects: hand C++ an opaque pointer, expose methods as functions.
// ---------------------------------------------------------------------------

/// An opaque counter. C++ only ever sees `Counter*`.
pub struct Counter {
    value: i64,
}

/// Creates a counter. Release it with `counter_free`.
#[no_mangle]
pub extern "C" fn counter_new(start: i64) -> *mut Counter {
    Box::into_raw(Box::new(Counter { value: start }))
}

/// Increments and returns the new value.
///
/// # Safety
/// `c` must be a live pointer from `counter_new`.
#[no_mangle]
pub unsafe extern "C" fn counter_increment(c: *mut Counter) -> i64 {
    let c = &mut *c;
    c.value += 1;
    c.value
}

/// Destroys a counter.
///
/// # Safety
/// `c` must come from `counter_new` and must not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn counter_free(c: *mut Counter) {
    if !c.is_null() {
        drop(Box::from_raw(c));
    }
}

// ---------------------------------------------------------------------------
// 5. Callbacks: C++ passes a function pointer, Rust calls it.
// ---------------------------------------------------------------------------

/// Calls `cb(i, user_data)` for every i in 0..n.
#[no_mangle]
pub extern "C" fn rs_for_each(
    n: u32,
    cb: extern "C" fn(u32, *mut c_void),
    user_data: *mut c_void,
) {
    for i in 0..n {
        cb(i, user_data);
    }
}
