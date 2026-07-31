{
  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
        inherit (pkgs) lib;

        flutterSdk = pkgs.flutter344;
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          includeNDK = true;
        };
        androidSdk = androidComposition.androidsdk;
        cmdlineToolsArchive = toString androidComposition."cmdline-tools-package".archives;
        cmdlineToolsMatch = builtins.match ".*-([0-9]+)_latest\\.zip" cmdlineToolsArchive;

        toolchainVersions = {
          rust = pkgs.rustc.version;
          flutter = flutterSdk.version;
          java = lib.versions.major pkgs.jdk.version;
          cargoNdk = pkgs.cargo-ndk.version;
          android = {
            platform = builtins.head androidComposition.platformVersions;
            compileSdk = lib.versions.major (builtins.head androidComposition.platformVersions);
            compileSdkMinor = lib.versions.minor (builtins.head androidComposition.platformVersions);
            buildTools = (builtins.head androidComposition."build-tools").version;
            ndk = androidComposition."ndk-bundle".version;
            cmdlineTools = builtins.head cmdlineToolsMatch;
          };
        };

        syncArgs = lib.escapeShellArgs [
          "--rust"
          toolchainVersions.rust
          "--flutter"
          toolchainVersions.flutter
          "--java"
          toolchainVersions.java
          "--cargo-ndk"
          toolchainVersions.cargoNdk
          "--android-platform"
          toolchainVersions.android.platform
          "--android-compile-sdk"
          toolchainVersions.android.compileSdk
          "--android-compile-sdk-minor"
          toolchainVersions.android.compileSdkMinor
          "--android-build-tools"
          toolchainVersions.android.buildTools
          "--android-ndk"
          toolchainVersions.android.ndk
          "--android-cmdline-tools"
          toolchainVersions.android.cmdlineTools
        ];
        syncToolchains = pkgs.writeShellApplication {
          name = "sync-toolchains";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            exec python3 ${./scripts/sync_toolchains.py} ${syncArgs} "$@"
          '';
        };

        astral-ng = pkgs.callPackage ./package.nix { };
      in
      {
        inherit toolchainVersions;

        packages = {
          inherit astral-ng syncToolchains;
          default = astral-ng;
        };

        apps.sync-toolchains = {
          type = "app";
          program = "${syncToolchains}/bin/sync-toolchains";
        };

        checks.toolchain-mirrors = pkgs.runCommand "toolchain-mirrors" { } ''
          cd ${./.}
          ${syncToolchains}/bin/sync-toolchains --check
          touch "$out"
        '';

        devShells.default =
          with pkgs;
          mkShell {
            name = "astral-dev";
            buildInputs = [
              rustc
              cargo
              rustup
              cargo-ndk
              flutterSdk
              androidSdk
              jdk
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
              JAVA_HOME = jdk.home;
              ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
              ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
              ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk/${toolchainVersions.android.ndk}";
              ACT_DISABLE_VERSION_CHECK = 1;
            };
            shellHook = ''
              export LD_LIBRARY_PATH="$PWD/build/lib:$LD_LIBRARY_PATH"
              export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$(echo "$ANDROID_HOME/build-tools/"*"/aapt2") ''${GRADLE_OPTS:-}"

              cat > android/local.properties <<EOF
              flutter.sdk=${flutterSdk}
              sdk.dir=$ANDROID_HOME
              ndk.dir=$ANDROID_NDK_ROOT
              EOF
            '';
          };
      }
    );
}
