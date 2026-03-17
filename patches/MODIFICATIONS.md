# EasyTier Vendored Copy Modifications

This document describes all local modifications made to the vendored EasyTier library
compared to upstream v2.5.0 (commit `88a45d115670631dfe6a05ba192387d615ddb95b`).

## Overview

The `rust/easytier/` directory contains a vendored copy of the EasyTier core library
from https://github.com/EasyTier/EasyTier with the following modifications.

---

## 1. Cargo.toml - TLS 1.2 Support

**File:** `Cargo.toml` (line 70)

**Change:** Added `"tls12"` feature to rustls dependency for backward compatibility.

```diff
 rustls = { version = "0.23.0", features = [
-    "ring",
+    "ring","tls12"
 ], default-features = false, optional = true }
```

**Reason:** Enables TLS 1.2 support for connecting to older servers that don't support TLS 1.3.

---

## 2. Platform-Specific Version Strings

**File:** `src/common/constants.rs` (lines 36-54)

**Change:** Replaced git-based version detection with platform-specific version strings.

**Original (upstream):**
```rust
pub const EASYTIER_VERSION: &str = git_version::git_version!(
    args = ["--abbrev=8", "--always", "--dirty=~"],
    prefix = concat!(env!("CARGO_PKG_VERSION"), "-"),
    suffix = "",
    fallback = env!("CARGO_PKG_VERSION")
);
```

**Modified:**
```rust
#[cfg(target_os = "android")]
pub const EASYTIER_VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "|Android");

#[cfg(target_os = "windows")]
pub const EASYTIER_VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "|Windows");

#[cfg(target_os = "linux")]
pub const EASYTIER_VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "|Linux");

#[cfg(target_os = "macos")]
pub const EASYTIER_VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "|macOS");

#[cfg(not(any(
    target_os = "android",
    target_os = "windows",
    target_os = "linux",
    target_os = "macos"
)))]
pub const EASYTIER_VERSION: &str = concat!(env!("CARGO_PKG_VERSION"), "|Unknown");
```

**Reason:**
- The `git_version` macro requires the source to be in a git repository
- Nix builds and other reproducible build environments often don't have git metadata
- Platform-specific version strings help identify which platform a binary was built for

---

## 3. Windows WinDivert Fallback Improvement

**File:** `src/tunnel/fake_tcp/netfilter/mod.rs` (lines 56-88)

**Change:** Improved Windows WinDivert fallback to PnetTun with proper interface name handling.

**Original (upstream):**
```rust
pub fn create_tun(
    _interface_name: &str,
    _src_addr: Option<SocketAddr>,
    local_addr: SocketAddr,
) -> io::Result<Arc<dyn super::stack::Tun>> {
    match windivert::WinDivertTun::new(local_addr) {
        Ok(tun) => Ok(Arc::new(tun)),
        Err(e) => {
            tracing::warn!(
                ?e,
                ?local_addr,
                "WinDivertTun init failed, falling back to PnetTun"
            );
            Ok(Arc::new(pnet::PnetTun::new(
                local_addr.to_string().as_str(),
                pnet::create_packet_filter(None, local_addr),
            )?))
        }
    }
}
```

**Modified:**
```rust
pub fn create_tun(
    interface_name: &str,
    src_addr: Option<SocketAddr>,
    local_addr: SocketAddr,
) -> io::Result<Arc<dyn super::stack::Tun>> {
    match windivert::WinDivertTun::new(local_addr) {
        Ok(tun) => Ok(Arc::new(tun)),
        Err(windivert_err) => {
            tracing::warn!(
                ?windivert_err,
                interface_name,
                ?local_addr,
                "WinDivertTun init failed, falling back to PnetTun"
            );

            if interface_name.is_empty() {
                return Err(io::Error::other(format!(
                    "WinDivert init failed ({windivert_err}); fallback requires a valid network interface name"
                )));
            }

            pnet::PnetTun::new(
                interface_name,
                pnet::create_packet_filter(src_addr, local_addr),
            )
                .map(|tun| Arc::new(tun) as Arc<dyn super::stack::Tun>)
                .map_err(|pnet_err| {
                    io::Error::new(
                        pnet_err.kind(),
                        format!(
                            "WinDivert init failed ({windivert_err}); fallback PnetTun failed on interface '{interface_name}' ({pnet_err})"
                        ),
                    )
                })
        }
    }
}
```

**Reason:**
- Properly propagates interface name and source address to PnetTun fallback
- Provides better error messages for debugging
- Returns error instead of silent failure when interface name is missing

---

## 4. Terminal UI (TUI) Client

**File:** `src/easytier-cli-tui.rs` (NEW FILE - ~1000 lines)

**Description:** A Terminal User Interface client for EasyTier using ratatui.

**Features:**
- Interactive terminal-based dashboard
- Real-time peer and route monitoring
- Keyboard navigation
- Network status visualization

**Dependencies added (implicitly):**
- `ratatui` - Terminal UI framework
- `crossterm` - Cross-platform terminal manipulation

---

## 5. Logger RPC Service

**File:** `src/instance/logger_rpc_service.rs` (NEW FILE)

**Description:** RPC service for remote logger configuration.

**Features:**
- Set log level remotely via RPC
- Get current log configuration
- Thread-safe log level management using channels

**Key components:**
```rust
pub static LOGGER_LEVEL_SENDER: OnceLock<Mutex<Sender<String>>> = OnceLock::new();
pub static CURRENT_LOG_LEVEL: OnceLock<Mutex<String>> = OnceLock::new();

pub struct LoggerRpcService;

impl LoggerRpc for LoggerRpcService {
    async fn set_logger_config(...) -> ...;
    async fn get_logger_config(...) -> ...;
}
```

---

## 6. CLI Protocol Buffer Definitions

**File:** `src/proto/cli.proto` (NEW FILE)
**File:** `src/proto/cli.rs` (NEW FILE - generated)

**Description:** Protocol buffer definitions for CLI RPC services.

**Services defined:**
- `PeerManageRpc` - Peer and route management
- `ConnectorManageRpc` - Connector management
- `MappedListenerManageRpc` - Listener management
- `VpnPortalRpc` - VPN portal info
- `TcpProxyRpc` - TCP proxy management
- `AclManageRpc` - ACL management
- `PortForwardManageRpc` - Port forwarding
- `StatsRpc` - Metrics and stats
- `LoggerRpc` - Logger configuration (new)

---

## 7. Windows DLLs in third_party

**Files:**
- `third_party/Packet.dll`
- `third_party/Packet.lib`
- `third_party/wintun.dll`

**Description:** Windows networking DLLs duplicated in root third_party directory.

**Note:** These files already exist in architecture-specific subdirectories
(`x86_64/`, `i686/`, `arm64/`). The duplication in root appears unintentional.

---

## License File Changes

**Files:** `LICENSE`, `README.md`, `README_CN.md`

**Change:** These are symlinks to the parent project's files.

- `LICENSE` -> `../LICENSE` (GPL-3.0 instead of LGPL-3.0)
- `README.md` -> `../README.md`
- `README_CN.md` -> `../README_CN.md`

---

## Applying Patches

To apply these modifications on top of the upstream submodule:

```bash
# After adding the submodule
cd rust/easytier
git apply ../../patches/easytier-modifications.patch
```

---

## Upstreaming Considerations

Some modifications could potentially be upstreamed:

1. **TLS 1.2 support** - Could be made configurable via feature flag
2. **Platform version strings** - Could be a separate feature for non-git builds
3. **Windows WinDivert fix** - Bug fix that benefits all users
4. **Logger RPC** - New feature that could be generally useful

The TUI client is likely too specific to this project's needs for upstreaming.
