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
        javaSdk = pkgs.jdk17;
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "36" ];
          buildToolsVersions = [ "35.0.0" ];
          includeCmake = true;
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          ndkVersions = [ "28.2.13676358" ];
        };
        androidSdk = androidComposition.androidsdk;
        cmdlineToolsArchive = toString androidComposition."cmdline-tools-package".archives;
        cmdlineToolsMatch = builtins.match ".*-([0-9]+)_latest\\.zip" cmdlineToolsArchive;
        androidPlatformVersion = builtins.head androidComposition.platformVersions;
        androidPlatformParts = lib.versions.splitVersion androidPlatformVersion;

        toolchainVersions = {
          rust = pkgs.rustc.version;
          flutter = flutterSdk.version;
          java = lib.versions.major javaSdk.version;
          cargoNdk = pkgs.cargo-ndk.version;
          android = {
            platform = androidPlatformVersion;
            compileSdk = builtins.head androidPlatformParts;
            compileSdkMinor =
              if builtins.length androidPlatformParts > 1 then builtins.elemAt androidPlatformParts 1 else "0";
            buildTools = (builtins.head androidComposition."build-tools").version;
            cmake = (builtins.head androidComposition.cmake).version;
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
          "--android-cmake"
          toolchainVersions.android.cmake
          "--android-ndk"
          toolchainVersions.android.ndk
          "--android-cmdline-tools"
          toolchainVersions.android.cmdlineTools
        ];
        syncToolchains = pkgs.writeShellApplication {
          name = "sync-toolchains";
          runtimeInputs = [ pkgs.python3 ];
          passthru = { inherit toolchainVersions; };
          meta.description = "Synchronize toolchain mirrors from locked nixpkgs";
          text = ''
            exec python3 ${./scripts/sync_toolchains.py} ${syncArgs} "$@"
          '';
        };
        flutterAndroid = pkgs.writeShellApplication {
          name = "flutter-android";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gawk
          ];
          runtimeEnv = {
            ASTRAL_FLUTTER_ROOT = "${flutterSdk}";
            ASTRAL_FLUTTER_BIN = "${flutterSdk.unwrapped}/bin/flutter";
            ASTRAL_ANDROID_MIN_SDK = "24";
          };
          meta.description = "Run Flutter with Astral-ng's Android-safe Nix environment";
          text = builtins.readFile ./scripts/flutter_android.sh;
        };

        astral-ng = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          inherit syncToolchains;
          flutter-android = flutterAndroid;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          inherit astral-ng;
          default = astral-ng;
        };

        apps.sync-toolchains = {
          type = "app";
          program = "${syncToolchains}/bin/sync-toolchains";
          meta.description = "Synchronize toolchain mirrors from locked nixpkgs";
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
              rustfmt
              cargo
              cargo-expand
              rustup
              cargo-ndk
              flutterSdk
              flutter_rust_bridge_codegen
              flutterAndroid
              androidSdk
              javaSdk
              protobuf
              python3
              clang
              libclang
              gradle
              gh
              jq
              lnav
              act
            ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [
              webkitgtk_4_1
              libayatana-appindicator
            ];

            nativeBuildInputs = [ pkg-config ];

            env = {
              RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
              LIBCLANG_PATH = "${libclang.lib}/lib";
              JAVA_HOME = javaSdk.home;
              ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
              ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
              ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk/${toolchainVersions.android.ndk}";
              ACT_DISABLE_VERSION_CHECK = 1;
            };
            shellHook = ''
              export LD_LIBRARY_PATH="$PWD/build/linux/x64/debug/bundle/lib:$LD_LIBRARY_PATH"
              export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$(echo "$ANDROID_HOME/build-tools/"*"/aapt2") ''${GRADLE_OPTS:-}"

              cat > android/gradlew <<'EOF'
              #!${runtimeShell}
              exec ${gradle}/bin/gradle "$@"
              EOF
              chmod +x android/gradlew

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
