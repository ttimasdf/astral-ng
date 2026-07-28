//! Windows MSVC links against Npcap `Packet.lib` / `wpcap.lib` (transitive deps).
//! CI sets `NPCAP_SDK_LIB` to the SDK `Lib\x64` directory; developers can mirror that layout under `third_party/`.

fn main() {
    #[cfg(all(windows, target_env = "msvc"))]
    npcap_link_search();

    #[cfg(not(all(windows, target_env = "msvc")))]
    let _ = ();
}

#[cfg(all(windows, target_env = "msvc"))]
fn npcap_link_search() {
    use std::path::{Path, PathBuf};

    fn emit_if_packet_lib(dir: &Path) -> bool {
        if dir.join("Packet.lib").is_file() {
            println!(
                "cargo:rustc-link-search=native={}",
                dir.display().to_string().replace('\\', "/")
            );
            return true;
        }
        false
    }

    if let Ok(dir) = std::env::var("NPCAP_SDK_LIB") {
        let path = PathBuf::from(dir);
        if emit_if_packet_lib(&path) {
            return;
        }
    }

    let manifest = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let candidates = [manifest.join("../third_party/npcap-sdk/Lib/x64")];

    for candidate in candidates {
        if emit_if_packet_lib(&candidate) {
            return;
        }
    }

    println!(
        "cargo:warning=Npcap SDK not found (need Packet.lib). Set NPCAP_SDK_LIB to the SDK Lib\\x64 directory or extract npcap-sdk under third_party/npcap-sdk/Lib/x64."
    );
}
