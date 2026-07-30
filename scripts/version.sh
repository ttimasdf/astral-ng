#!/usr/bin/env bash
# Resolve application versions for local and GitHub Actions builds.
# Prints KEY=VALUE lines suitable for appending to GITHUB_ENV.
set -euo pipefail

root_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck disable=SC1091
source "$root_dir/VERSION"

if [[ ! ${VERSION:-} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must be MAJOR.MINOR.PATCH" >&2
  exit 1
fi
if [[ ! ${BUILD_NUMBER:-} =~ ^[1-9][0-9]*$ ]]; then
  echo "BUILD_NUMBER must be a positive integer" >&2
  exit 1
fi

mode=${1:-auto}
if [[ $mode == auto ]]; then
  if [[ ${GITHUB_REF_TYPE:-} == tag || ${GITHUB_REF:-} == "refs/tags/"* ]]; then
    mode=production
  else
    mode=canary
  fi
fi

case "$mode" in
  production)
    tag=${GITHUB_REF_NAME:-${GITHUB_REF:-}}
    tag=${tag#refs/tags/}
    if [[ -n ${GITHUB_ACTIONS:-} && $tag != "v$VERSION" ]]; then
      echo "Production tag must be v$VERSION; got $tag" >&2
      exit 1
    fi
    channel=production
    build_number=$BUILD_NUMBER
    asset_version="v$VERSION"
    ;;
  canary)
    run_number=${GITHUB_RUN_NUMBER:-0}
    if [[ ! $run_number =~ ^[0-9]+$ ]]; then
      echo "GITHUB_RUN_NUMBER must be numeric" >&2
      exit 1
    fi
    # Keep canary Android versionCodes distinct from releases and below 2^31.
    build_number=$((1000000000 + run_number))
    if (( build_number > 2147483647 )); then
      echo "Canary build number exceeds Android's versionCode limit" >&2
      exit 1
    fi
    short_sha=${GITHUB_SHA:-$(git -C "$root_dir" rev-parse --short HEAD 2>/dev/null || echo local)}
    short_sha=${short_sha:0:12}
    channel=canary
    asset_version="v$VERSION-canary.$run_number-$short_sha"
    ;;
  *)
    echo "Usage: $0 [auto|production|canary]" >&2
    exit 2
    ;;
esac

cat <<EOF
VERSION_BASE=$VERSION
BUILD_CHANNEL=$channel
FLUTTER_BUILD_NAME=$VERSION
FLUTTER_BUILD_NUMBER=$build_number
PACKAGE_VERSION=$VERSION.$build_number
ASSET_VERSION=$asset_version
EOF
