{
  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };
        flutterVersion = (builtins.fromJSON (builtins.readFile ./.fvmrc)).flutter;
        flutterSdk =
          assert pkgs.lib.assertMsg (
            pkgs.flutter344.version == flutterVersion
          ) "Flutter pin ${flutterVersion} does not match nixpkgs flutter344 ${pkgs.flutter344.version}";
          pkgs.flutter344;
        astral-ng = pkgs.callPackage ./package.nix {
          inherit rustPlatform;
          flutter344 = flutterSdk;
        };
      in
      {
        packages = {
          inherit astral-ng;
          default = astral-ng;
        };
        devShells.default =
          with pkgs;
          mkShell {
            name = "astral-dev";
            buildInputs = [
              rustToolchain
              flutterSdk
              rustup
              protobuf
              webkitgtk_4_1
              libayatana-appindicator
              clang
              libclang
              act
            ];

            nativeBuildInputs = [ pkg-config ];

            env = {
              RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
              LIBCLANG_PATH = "${libclang.lib}/lib";
              ACT_DISABLE_VERSION_CHECK = 1;
            };
            shellHook = ''
              export LD_LIBRARY_PATH="$PWD/build/lib:$LD_LIBRARY_PATH"
            '';
          };
      }

    );
}
