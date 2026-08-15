#!/usr/bin/env bash

fail() {
  printf 'flutter: %s\n' "$*" >&2
  exit 2
}

: "${ASTRAL_FLUTTER_BIN:?the Astral-ng flutter wrapper requires the Nix development shell}"

channel="${BUILD_CHANNEL:-canary}"
explicit_channel=false
explicit_update_api_base_url=false
expect_dart_define_value=false
flutter_command=""

for argument in "$@"; do
  if [[ "$expect_dart_define_value" == true ]]; then
    if [[ "$argument" == BUILD_CHANNEL=* ]]; then
      channel="${argument#BUILD_CHANNEL=}"
      explicit_channel=true
    elif [[ "$argument" == UPDATE_API_BASE_URL=* ]]; then
      explicit_update_api_base_url=true
    fi
    expect_dart_define_value=false
    continue
  fi

  case "$argument" in
    --dart-define)
      expect_dart_define_value=true
      ;;
    --dart-define=BUILD_CHANNEL=*)
      channel="${argument#--dart-define=BUILD_CHANNEL=}"
      explicit_channel=true
      ;;
    --dart-define=UPDATE_API_BASE_URL=*)
      explicit_update_api_base_url=true
      ;;
  esac

  if [[ -z "$flutter_command" ]]; then
    case "$argument" in
      build|drive|run|test)
        flutter_command="$argument"
        ;;
      analyze|attach|channel|clean|config|create|custom-devices|daemon|debug-adapter|devices|doctor|downgrade|emulators|gen-l10n|install|logs|precache|pub|screenshot|symbolize|upgrade)
        flutter_command="$argument"
        ;;
    esac
  fi
done

if [[ "$channel" != production && "$channel" != canary ]]; then
  fail "unsupported BUILD_CHANNEL '$channel'; expected production or canary"
fi

build_commit="${BUILD_COMMIT:-$(git rev-parse --short=7 HEAD 2>/dev/null || printf local)}"
build_run_number="${BUILD_RUN_NUMBER:-${GITHUB_RUN_NUMBER:-0}}"
[[ "$build_run_number" =~ ^[0-9]+$ ]] ||
  fail "unsupported BUILD_RUN_NUMBER '$build_run_number'; expected a non-negative integer"

export BUILD_CHANNEL="$channel"
export BUILD_COMMIT="$build_commit"
export BUILD_RUN_NUMBER="$build_run_number"
flutter_args=("$@")
case "$flutter_command" in
  build|drive|run|test)
    if [[ "$explicit_channel" == false ]]; then
      flutter_args+=("--dart-define=BUILD_CHANNEL=$channel")
    fi
    flutter_args+=(
      "--dart-define=BUILD_COMMIT=$build_commit"
      "--dart-define=BUILD_RUN_NUMBER=$build_run_number"
    )
    if [[ "$explicit_update_api_base_url" == false && -n "${UPDATE_API_BASE_URL:-}" ]]; then
      flutter_args+=("--dart-define=UPDATE_API_BASE_URL=$UPDATE_API_BASE_URL")
    fi
    ;;
esac

exec "$ASTRAL_FLUTTER_BIN" "${flutter_args[@]}"
