#!/usr/bin/env bash
# Ignored Build Step check for the update-server Vercel project.
#
# Vercel semantics (see
# https://vercel.com/kb/guide/how-do-i-use-the-ignored-build-step-field-on-vercel):
#   exit 0  -> skip the build
#   exit 1+ -> proceed with the build
#
# Dashboard field (Root Directory = update-server/):
#   bash scripts/vercel-build-check.sh
#
# Vercel performs a shallow clone, so VERCEL_GIT_PREVIOUS_SHA can reference a
# commit that is absent from the checkout (observed as `fatal: bad object` on
# the v3.0.0 release push). This script tolerates that case instead of
# crashing, and adds an environment/branch guard for production deployments.
set -u

# Reuse the project's default-branch override when present (custom env vars
# may not be exposed to the ignored build step; `main` remains the default).
MAIN_BRANCH="${GITHUB_DEFAULT_BRANCH:-main}"

info() { printf 'vercel-build-check: %s\n' "$*"; }
warn() { printf 'vercel-build-check: WARNING: %s\n' "$*" >&2; }
error() { printf 'vercel-build-check: ERROR: %s\n' "$*" >&2; }

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! git -C "$APP_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  warn "not inside a Git checkout; cannot determine changes; proceeding with build."
  exit 1
fi
cd "$APP_DIR" || exit 1

DEPLOY_ENV="${VERCEL_ENV:-}"
BRANCH="${VERCEL_GIT_COMMIT_REF:-}"
PREV="${VERCEL_GIT_PREVIOUS_SHA:-}"
CUR="${VERCEL_GIT_COMMIT_SHA:-HEAD}"

# 1. Production deployments must come from the default branch.
if [ "$DEPLOY_ENV" = "production" ] && [ "$BRANCH" != "$MAIN_BRANCH" ]; then
  error "VERCEL_ENV=production but branch is '${BRANCH:-<unset>}' (expected '${MAIN_BRANCH}'); cancelling build."
  exit 0
fi

# 2. Empty previous SHA (e.g. first deployment): nothing to diff against.
if [ -z "$PREV" ]; then
  warn "VERCEL_GIT_PREVIOUS_SHA is empty; cannot diff; proceeding with build."
  exit 1
fi

# A previous SHA is usable only when its commit exists in the checkout and is
# part of the current branch's history.
commit_usable() {
  local sha="$1"
  git cat-file -e "${sha}^{commit}" 2>/dev/null || return 1
  git merge-base --is-ancestor "$sha" "$CUR" 2>/dev/null || return 1
}

# 3. Resolve the diff base: the previous commit as usual; otherwise a
#    main-branch fallback for previews, or fail open for production.
if commit_usable "$PREV"; then
  BASE="$PREV"
else
  warn "VERCEL_GIT_PREVIOUS_SHA (${PREV}) is invalid or not in the current branch history."
  if [ "$DEPLOY_ENV" = "production" ]; then
    warn "production deployment: cannot determine changed paths; proceeding with build."
    exit 1
  fi
  BASE="$(git rev-parse --verify --quiet "origin/${MAIN_BRANCH}^{commit}")"
  if [ -z "$BASE" ]; then
    info "'origin/${MAIN_BRANCH}' is missing from the shallow clone; fetching..."
    if ! git fetch --quiet --depth=1 origin "$MAIN_BRANCH" 2>/dev/null; then
      warn "could not fetch '${MAIN_BRANCH}'; proceeding with build."
      exit 1
    fi
    BASE="$(git rev-parse --verify --quiet "FETCH_HEAD^{commit}")"
  fi
  if [ -z "$BASE" ]; then
    warn "could not resolve '${MAIN_BRANCH}'; proceeding with build."
    exit 1
  fi
  info "diffing against '${MAIN_BRANCH}' (${BASE}) instead."
fi

# 4. Diff update-server/ between the base and the pushed commit. A git error
#    (e.g. another bad object) falls through to "changes detected" so the
#    build fails open instead of being skipped.
if git diff --quiet "$BASE" "$CUR" -- . 2>/dev/null; then
  info "no changes under update-server/ between ${BASE:0:12} and ${CUR:0:12}; skipping build."
  exit 0
fi

info "changes detected under update-server/ between ${BASE:0:12} and ${CUR:0:12}; proceeding with build."
exit 1
