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
        flutterDev = pkgs.writeShellApplication {
          name = "flutter";
          runtimeEnv = {
            ASTRAL_FLUTTER_BIN = "${flutterSdk}/bin/flutter";
          };
          meta.description = "Run Flutter with Astral-ng's default canary identity";
          text = builtins.readFile ./scripts/flutter_dev.sh;
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

        checks = {
          toolchain-mirrors = pkgs.runCommand "toolchain-mirrors" { } ''
            cd ${./.}
            ${syncToolchains}/bin/sync-toolchains --check
            touch "$out"
          '';
          version-semantics = pkgs.runCommand "version-semantics" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            cd ${./.}
            python3 test/scripts/version_test.py
            touch "$out"
          '';
          flutter-dev-channel =
            pkgs.runCommand "flutter-dev-channel"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                ];
              }
              ''
                fake_flutter="$TMPDIR/flutter"
                args_file="$TMPDIR/args"
                channel_file="$TMPDIR/channel"
                cat > "$fake_flutter" <<'EOF'
                #!${pkgs.runtimeShell}
                printf '%s\n' "$@" > "$ASTRAL_TEST_ARGS_FILE"
                printf '%s\n' "$BUILD_CHANNEL" > "$ASTRAL_TEST_CHANNEL_FILE"
                EOF
                chmod +x "$fake_flutter"

                env -u BUILD_CHANNEL \
                  BUILD_COMMIT=abcdef0 \
                  BUILD_RUN_NUMBER=42 \
                  ASTRAL_FLUTTER_BIN="$fake_flutter" \
                  ASTRAL_TEST_ARGS_FILE="$args_file" \
                  ASTRAL_TEST_CHANNEL_FILE="$channel_file" \
                  bash ${./scripts/flutter_dev.sh} run -d linux
                grep -Fx -- '--dart-define=BUILD_CHANNEL=canary' "$args_file"
                grep -Fx -- '--dart-define=BUILD_COMMIT=abcdef0' "$args_file"
                grep -Fx -- '--dart-define=BUILD_RUN_NUMBER=42' "$args_file"
                grep -Fx -- 'canary' "$channel_file"

                UPDATE_API_BASE_URL=https://updates.example/api/v1 \
                  BUILD_COMMIT=abcdef0 \
                  BUILD_RUN_NUMBER=42 \
                  ASTRAL_FLUTTER_BIN="$fake_flutter" \
                  ASTRAL_TEST_ARGS_FILE="$args_file" \
                  ASTRAL_TEST_CHANNEL_FILE="$channel_file" \
                  bash ${./scripts/flutter_dev.sh} run -d linux
                grep -Fx -- '--dart-define=UPDATE_API_BASE_URL=https://updates.example/api/v1' "$args_file"

                BUILD_CHANNEL=canary \
                  BUILD_COMMIT=abcdef0 \
                  BUILD_RUN_NUMBER=42 \
                  ASTRAL_FLUTTER_BIN="$fake_flutter" \
                  ASTRAL_TEST_ARGS_FILE="$args_file" \
                  ASTRAL_TEST_CHANNEL_FILE="$channel_file" \
                  bash ${./scripts/flutter_dev.sh} run \
                    --dart-define=BUILD_CHANNEL=production
                test "$(grep -Fxc -- '--dart-define=BUILD_CHANNEL=production' "$args_file")" -eq 1
                grep -Fx -- 'production' "$channel_file"

                UPDATE_API_BASE_URL=https://environment.example/api/v1 \
                  BUILD_COMMIT=abcdef0 \
                  BUILD_RUN_NUMBER=42 \
                  ASTRAL_FLUTTER_BIN="$fake_flutter" \
                  ASTRAL_TEST_ARGS_FILE="$args_file" \
                  ASTRAL_TEST_CHANNEL_FILE="$channel_file" \
                  bash ${./scripts/flutter_dev.sh} run \
                    --dart-define=UPDATE_API_BASE_URL=https://explicit.example/api/v1
                test "$(grep -Fxc -- '--dart-define=UPDATE_API_BASE_URL=https://explicit.example/api/v1' "$args_file")" -eq 1
                test "$(grep -Fxc -- '--dart-define=UPDATE_API_BASE_URL=https://environment.example/api/v1' "$args_file")" -eq 0

                touch "$out"
              '';
        };

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
              easytier
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

            nativeBuildInputs = [
              flutterDev
              pkg-config
            ];

            env = {
              RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
              LIBCLANG_PATH = "${libclang.lib}/lib";
              JAVA_HOME = javaSdk.home;
              ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
              ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
              ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk/${toolchainVersions.android.ndk}";
              ACT_DISABLE_VERSION_CHECK = 1;
              BUILD_CHANNEL = "canary";
            };
            shellHook = ''
              export PATH="${flutterDev}/bin:$PATH"
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
