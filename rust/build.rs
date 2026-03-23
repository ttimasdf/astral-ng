use std::env;

fn main() {
    let target = env::var("TARGET").unwrap_or_default();

    // Only needed for Windows builds
    if !target.contains("windows") {
        return;
    }

    // The easytier crate is at ./easytier/easytier
    // and its third_party directory contains Packet.lib, WinDivert64.sys, etc.
    let third_party_path = if target.contains("x86_64") {
        "easytier/easytier/third_party/x86_64"
    } else if target.contains("i686") {
        "easytier/easytier/third_party/i686"
    } else if target.contains("aarch64") {
        "easytier/easytier/third_party/arm64"
    } else {
        return;
    };

    println!("cargo:rustc-link-search=native={}", third_party_path);
}
