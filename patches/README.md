# EasyTier Patches

This directory contains patches to apply on top of the upstream EasyTier submodule.

## Files

| File | Description |
|------|-------------|
| `easytier-core.patch` | Core modifications (Cargo.toml, constants.rs, netfilter/mod.rs) |
| `cli.proto` | New file: Protocol buffer definitions for CLI RPC |
| `cli.rs` | New file: Generated Rust code for CLI protobuf |
| `easytier-cli-tui.rs` | New file: Terminal UI client |
| `logger_rpc_service.rs` | New file: Logger RPC service implementation |

## Applying Patches

After setting up the submodule, apply patches:

```bash
cd rust/easytier

# Apply core patch
git apply ../../patches/easytier-core.patch

# Copy new files
cp ../../patches/cli.proto src/proto/
cp ../../patches/cli.rs src/proto/
cp ../../patches/easytier-cli-tui.rs src/
cp ../../patches/logger_rpc_service.rs src/instance/
```

## Updating Patches

If you make changes to the vendored copy and want to update the patches:

```bash
# Clone upstream for comparison
git clone --depth 1 --branch v2.5.0 https://github.com/EasyTier/EasyTier.git /tmp/easytier-upstream

# Generate patch
diff -ru /tmp/easytier-upstream/easytier rust/easytier > patches/easytier-core.patch

# Copy new files
cp rust/easytier/src/proto/cli.proto patches/
cp rust/easytier/src/proto/cli.rs patches/
cp rust/easytier/src/easytier-cli-tui.rs patches/
cp rust/easytier/src/instance/logger_rpc_service.rs patches/
```

## Patch Details

See `rust/easytier/MODIFICATIONS.md` for detailed documentation of each modification.
