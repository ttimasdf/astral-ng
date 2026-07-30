#!/usr/bin/env bash
# Synchronize or verify pubspec.yaml's Flutter-required version mirror.
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC1091
source "$root_dir/VERSION"
expected="version: $VERSION+$BUILD_NUMBER"
actual=$(grep -E '^version: ' "$root_dir/pubspec.yaml" | head -n 1 || true)

if [[ ${1:-} == --check ]]; then
  if [[ $actual != "$expected" ]]; then
    echo "pubspec.yaml version drift: expected '$expected', got '$actual'" >&2
    exit 1
  fi
  exit 0
fi

if [[ -n ${1:-} ]]; then
  echo "Usage: $0 [--check]" >&2
  exit 2
fi

EXPECTED=$expected perl -0pi -e 's/^version: .*/$ENV{EXPECTED}/m' "$root_dir/pubspec.yaml"
