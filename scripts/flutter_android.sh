#!/usr/bin/env bash

usage() {
  cat <<'EOF'
Usage: flutter-android [ENMESH_OPTIONS] <flutter-command> [flutter-arguments...]

Run Flutter with an Android-safe Nix environment while preserving Flutter's
normal subcommands and arguments.

Enmesh options (must precede the Flutter command):
  --enmesh-channel CHANNEL  Set production or canary build identity.
                            Defaults to canary.
  --enmesh-channel=CHANNEL  Equivalent inline form.
  --enmesh-update-api URL   Compile an update API base URL into the app.
  --enmesh-update-api=URL   Equivalent inline form.
  --enmesh-help             Show this help text.

Examples:
  flutter-android run -d <device>
  flutter-android test
  flutter-android build apk --debug
  flutter-android --enmesh-channel production build apk --release
  flutter-android --enmesh-update-api http://10.0.2.2:3100/api/v1 run -d <device>
EOF
}

fail() {
  printf 'flutter-android: %s\n' "$*" >&2
  exit 2
}

enmesh_channel="canary"
enmesh_update_api="${UPDATE_API_BASE_URL:-}"
has_flutter_update_api_define=false
while (( $# > 0 )); do
  case "$1" in
    --enmesh-channel)
      (( $# >= 2 )) || fail '--enmesh-channel requires production or canary'
      enmesh_channel="$2"
      shift 2
      ;;
    --enmesh-channel=*)
      enmesh_channel="${1#*=}"
      shift
      ;;
    --enmesh-update-api)
      (( $# >= 2 )) || fail '--enmesh-update-api requires a URL'
      enmesh_update_api="$2"
      shift 2
      ;;
    --enmesh-update-api=*)
      enmesh_update_api="${1#*=}"
      shift
      ;;
    --enmesh-help)
      usage
      exit 0
      ;;
    --enmesh-*)
      fail "unknown Enmesh option: $1"
      ;;
    *)
      break
      ;;
  esac
done

if [[ "$enmesh_channel" != "production" && "$enmesh_channel" != "canary" ]]; then
  fail "unsupported channel '$enmesh_channel'; expected production or canary"
fi

[[ "$(uname -s)" == "Linux" ]] || fail 'the Nix Android wrapper currently supports Linux only'
[[ -f pubspec.yaml && -x android/gradlew ]] || fail 'run this command from the Enmesh repository root'

: "${ENMESH_FLUTTER_ROOT:?flutter-android must be launched from the Nix development shell}"
: "${ENMESH_FLUTTER_BIN:?flutter-android must be launched from the Nix development shell}"
: "${ENMESH_ANDROID_MIN_SDK:?flutter-android is missing its pinned Android minimum SDK}"
: "${ANDROID_NDK_ROOT:?ANDROID_NDK_ROOT is not set; enter the Nix development shell}"

flutter_command="${1:-}"
case "$flutter_command" in
  build|drive|run)
    available_kib="$(df -Pk . | awk 'NR == 2 { print $4 }')"
    warning_threshold_kib=$((30 * 1024 * 1024))
    if [[ "$available_kib" =~ ^[0-9]+$ ]] && (( available_kib < warning_threshold_kib )); then
      available_gib=$((available_kib / 1024 / 1024))
      printf 'flutter-android: warning: only %d GiB free; a clean Android build can use about 22 GiB\n' \
        "$available_gib" >&2
    fi

    # Gradle daemons retain the environment from their first invocation. Stop
    # compatible daemons so this command's sanitized Android environment wins.
    ./android/gradlew --stop >/dev/null 2>&1 || true
    ;;
esac

prebuilt="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64"
sysroot="$prebuilt/sysroot"
[[ -d "$sysroot/usr/include" ]] || fail "Android NDK sysroot not found at $sysroot"

shopt -s nullglob
clang_include_dirs=("$prebuilt"/lib/clang/*/include)
shopt -u nullglob
(( ${#clang_include_dirs[@]} == 1 )) || fail "expected one NDK Clang include directory under $prebuilt/lib/clang"
clang_include="${clang_include_dirs[0]}"

for target_include in \
  arm-linux-androideabi \
  aarch64-linux-android \
  i686-linux-android \
  x86_64-linux-android; do
  [[ -d "$sysroot/usr/include/$target_include" ]] || fail "NDK headers not found for $target_include"
done

bindgen_args() {
  local clang_target="$1"
  local target_include="$2"
  printf '%s' \
    "--target=${clang_target}${ENMESH_ANDROID_MIN_SDK} " \
    "--sysroot=$sysroot " \
    "-nostdinc " \
    "-isystem $clang_include " \
    "-isystem $sysroot/usr/include/$target_include " \
    "-isystem $sysroot/usr/include"
}

# nixpkgs' Linux Flutter wrapper injects desktop C/C++ search paths. They are
# valid for Linux builds but contaminate NDK compilation and bindgen.
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LIBRARY_PATH CPATH
unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH PKG_CONFIG_PATH
unset NIX_CFLAGS_COMPILE NIX_CFLAGS_COMPILE_FOR_BUILD NIX_CFLAGS_COMPILE_FOR_TARGET
unset NIX_LDFLAGS NIX_LDFLAGS_FOR_BUILD NIX_LDFLAGS_FOR_TARGET NIX_ENFORCE_NO_NATIVE

BINDGEN_EXTRA_CLANG_ARGS_armv7_linux_androideabi="$(bindgen_args armv7a-linux-androideabi arm-linux-androideabi)"
BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android="$(bindgen_args aarch64-linux-android aarch64-linux-android)"
BINDGEN_EXTRA_CLANG_ARGS_i686_linux_android="$(bindgen_args i686-linux-android i686-linux-android)"
BINDGEN_EXTRA_CLANG_ARGS_x86_64_linux_android="$(bindgen_args x86_64-linux-android x86_64-linux-android)"
export BINDGEN_EXTRA_CLANG_ARGS_armv7_linux_androideabi
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_linux_android
export BINDGEN_EXTRA_CLANG_ARGS_i686_linux_android
export BINDGEN_EXTRA_CLANG_ARGS_x86_64_linux_android
export FLUTTER_ROOT="$ENMESH_FLUTTER_ROOT"

build_commit="${BUILD_COMMIT:-$(git rev-parse --short=7 HEAD 2>/dev/null || printf local)}"
build_run_number="${BUILD_RUN_NUMBER:-${GITHUB_RUN_NUMBER:-0}}"
[[ "$build_run_number" =~ ^[0-9]+$ ]] ||
  fail "unsupported BUILD_RUN_NUMBER '$build_run_number'; expected a non-negative integer"

flutter_args=("$@")
expect_dart_define_value=false
for argument in "${flutter_args[@]}"; do
  if [[ "$expect_dart_define_value" == true ]]; then
    if [[ "$argument" == UPDATE_API_BASE_URL=* ]]; then
      has_flutter_update_api_define=true
    fi
    expect_dart_define_value=false
    continue
  fi
  case "$argument" in
    --dart-define)
      expect_dart_define_value=true
      ;;
    --dart-define=UPDATE_API_BASE_URL=*)
      has_flutter_update_api_define=true
      ;;
  esac
done

export BUILD_CHANNEL="$enmesh_channel"
export BUILD_COMMIT="$build_commit"
export BUILD_RUN_NUMBER="$build_run_number"
case "$flutter_command" in
  build|drive|run|test)
    flutter_args+=(
      "--dart-define=BUILD_CHANNEL=$enmesh_channel"
      "--dart-define=BUILD_COMMIT=$build_commit"
      "--dart-define=BUILD_RUN_NUMBER=$build_run_number"
    )
    if [[ "$has_flutter_update_api_define" == false && -n "$enmesh_update_api" ]]; then
      flutter_args+=("--dart-define=UPDATE_API_BASE_URL=$enmesh_update_api")
    fi
    ;;
esac

exec "$ENMESH_FLUTTER_BIN" "${flutter_args[@]}"
