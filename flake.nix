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
        astral-ng = pkgs.callPackage ./package.nix {};
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
              rust-bin.beta.latest.default
              flutter
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
              RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
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
