#!/usr/bin/env bash

fail() {
  printf 'flutter: %s\n' "$*" >&2
  exit 2
}

: "${ASTRAL_FLUTTER_BIN:?the Astral-ng flutter wrapper requires the Nix development shell}"

channel="${BUILD_CHANNEL:-canary}"
explicit_channel=false
expect_dart_define_value=false
flutter_command=""

for argument in "$@"; do
  if [[ "$expect_dart_define_value" == true ]]; then
    if [[ "$argument" == BUILD_CHANNEL=* ]]; then
      channel="${argument#BUILD_CHANNEL=}"
      explicit_channel=true
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

export BUILD_CHANNEL="$channel"
flutter_args=("$@")
case "$flutter_command" in
  build|drive|run|test)
    if [[ "$explicit_channel" == false ]]; then
      flutter_args+=("--dart-define=BUILD_CHANNEL=$channel")
    fi
    ;;
esac

exec "$ASTRAL_FLUTTER_BIN" "${flutter_args[@]}"
