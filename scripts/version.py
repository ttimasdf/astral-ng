#!/usr/bin/env python3
"""Resolve, validate, synchronize, and bump Enmesh application versions."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION_FILE = ROOT / "VERSION"
PUBSPEC_FILE = ROOT / "pubspec.yaml"
VERSION_PATTERN = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
RC_TAG_PATTERN = re.compile(r"^v(\d+\.\d+\.\d+)-rc\.([1-9]\d*)$")
PUBSPEC_PATTERN = re.compile(r"^version: .*$", re.MULTILINE)
CANARY_BUILD_OFFSET = 1_000_000_000
ANDROID_VERSION_CODE_LIMIT = 2_147_483_647
SHORT_COMMIT_LENGTH = 7
MERGED_PULL_REQUEST_PATTERN = re.compile(r" \(#[1-9]\d*\)$")
CANARY_RETENTION_DAYS = 30
MERGED_PULL_REQUEST_RETENTION_DAYS = 90
PRODUCTION_RETENTION_DAYS = 90


@dataclass(frozen=True)
class SourceVersion:
    version: str
    build_number: int


@dataclass(frozen=True)
class BuildVersion:
    source: SourceVersion
    channel: str
    stage: str
    build_number: int
    run_number: int
    git_ref: str
    commit: str
    prerelease_number: int | None = None

    @property
    def semantic_version(self) -> str:
        if self.stage == "stable":
            return self.source.version
        number = self.prerelease_number or self.run_number
        metadata = "" if self.stage == "rc" else f"+{self.commit}"
        return f"{self.source.version}-{self.stage}.{number}{metadata}"

    @property
    def package_version(self) -> str:
        if self.stage == "stable":
            return self.source.version
        number = self.prerelease_number or self.run_number
        metadata = "" if self.stage == "rc" else f"+{self.commit}"
        # Debian and RPM use ~ to order prereleases before the final version.
        return f"{self.source.version}~{self.stage}.{number}{metadata}"

    @property
    def asset_version(self) -> str:
        return self.semantic_version

    @property
    def is_prerelease(self) -> bool:
        return self.stage != "stable"


def fail(message: str) -> None:
    raise ValueError(message)


def git_value(*args: str, fallback: str) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(ROOT), *args],
            text=True,
            encoding="utf-8",
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return fallback


def pull_request_head_commit() -> str:
    event_path = os.getenv("GITHUB_EVENT_PATH", "")
    if not event_path:
        return ""
    try:
        event = json.loads(Path(event_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ""
    pull_request = event.get("pull_request")
    if not isinstance(pull_request, dict):
        return ""
    head = pull_request.get("head")
    if not isinstance(head, dict):
        return ""
    sha = head.get("sha")
    return sha if isinstance(sha, str) else ""


def read_source() -> SourceVersion:
    values: dict[str, str] = {}
    for line in VERSION_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            key, separator, value = line.partition("=")
            if not separator:
                fail(f"Invalid VERSION entry: {line}")
            values[key] = value

    version = values.get("VERSION", "")
    if not VERSION_PATTERN.fullmatch(version):
        fail("VERSION must be MAJOR.MINOR.PATCH")
    try:
        build_number = int(values["BUILD_NUMBER"])
    except (KeyError, ValueError):
        fail("BUILD_NUMBER must be a positive integer")
    if build_number < 1:
        fail("BUILD_NUMBER must be a positive integer")
    return SourceVersion(version, build_number)


def resolve(channel: str) -> BuildVersion:
    source = read_source()
    github_ref = os.getenv("GITHUB_REF", "")
    github_ref_name = os.getenv("GITHUB_REF_NAME", "")
    if channel == "auto":
        channel = "production" if github_ref.startswith("refs/tags/") else "canary"

    commit_source = pull_request_head_commit() if github_ref.startswith("refs/pull/") else ""
    commit = (commit_source or os.getenv("GITHUB_SHA", ""))[:SHORT_COMMIT_LENGTH] or git_value(
        "rev-parse", f"--short={SHORT_COMMIT_LENGTH}", "HEAD", fallback="local"
    )
    git_ref = github_ref_name or git_value(
        "branch", "--show-current", fallback="detached"
    )

    try:
        run_number = int(os.getenv("GITHUB_RUN_NUMBER", "0"))
    except ValueError:
        fail("GITHUB_RUN_NUMBER must be numeric")
    if run_number < 0:
        fail("GITHUB_RUN_NUMBER must not be negative")

    if channel == "production":
        tag = github_ref_name or github_ref.removeprefix("refs/tags/")
        stable_tag = f"v{source.version}"
        rc_match = RC_TAG_PATTERN.fullmatch(tag)
        if os.getenv("GITHUB_ACTIONS") and not (
            tag == stable_tag or (rc_match and rc_match.group(1) == source.version)
        ):
            fail(
                f"Production tag must be {stable_tag} or {stable_tag}-rc.N; "
                f"got {tag or '<none>'}"
            )
        stage = "rc" if rc_match else "stable"
        prerelease_number = int(rc_match.group(2)) if rc_match else None
        return BuildVersion(
            source,
            channel,
            stage,
            source.build_number,
            run_number,
            git_ref,
            commit,
            prerelease_number,
        )

    if channel == "canary":
        stage = "beta" if github_ref == "refs/heads/main" else "alpha"
        build_number = CANARY_BUILD_OFFSET + run_number
        if build_number > ANDROID_VERSION_CODE_LIMIT:
            fail("Canary build number exceeds Android's versionCode limit")
        return BuildVersion(
            source,
            channel,
            stage,
            build_number,
            run_number,
            git_ref,
            commit,
        )

    fail("Channel must be auto, production, or canary")


def artifact_retention_days(
    *, channel: str, event_name: str, git_ref: str, commit_subject: str
) -> int:
    if channel == "production":
        return PRODUCTION_RETENTION_DAYS
    if (
        event_name == "push"
        and git_ref == "refs/heads/main"
        and MERGED_PULL_REQUEST_PATTERN.search(commit_subject)
    ):
        return MERGED_PULL_REQUEST_RETENTION_DAYS
    return CANARY_RETENTION_DAYS


def emit(build: BuildVersion, output_format: str) -> None:
    is_canary = build.channel == "canary"
    retention_days = artifact_retention_days(
        channel=build.channel,
        event_name=os.getenv("GITHUB_EVENT_NAME", ""),
        git_ref=os.getenv("GITHUB_REF", ""),
        commit_subject=git_value("log", "-1", "--format=%s", fallback=""),
    )
    values = {
        "VERSION_BASE": build.source.version,
        "BUILD_CHANNEL": build.channel,
        "BUILD_STAGE": build.stage,
        "BUILD_COMMIT": build.commit,
        "BUILD_RUN_NUMBER": str(build.run_number),
        "SEMANTIC_VERSION": build.semantic_version,
        "FLUTTER_BUILD_NAME": build.source.version,
        "FLUTTER_BUILD_NUMBER": str(build.build_number),
        "PACKAGE_VERSION": build.package_version,
        "ASSET_VERSION": build.asset_version,
        "IS_PRERELEASE": str(build.is_prerelease).lower(),
        "APP_DISPLAY_NAME": "Enmesh Canary" if is_canary else "Enmesh",
        "APP_PACKAGE_ID": "pw.rabit.enmesh.canary"
        if is_canary
        else "pw.rabit.enmesh",
        "APP_EXECUTABLE": "enmesh-canary" if is_canary else "enmesh",
        "LINUX_PACKAGE_NAME": "enmesh-canary" if is_canary else "enmesh",
        "WINDOWS_APP_ID": (
            "{E193416A-7545-4559-BB79-95858B8796EB}"
            if is_canary
            else "{9A41EC10-FBE6-4B63-8B18-A466907374B5}"
        ),
    }
    if output_format == "github-actions-output":
        step_outputs = {
            key.lower(): value
            for key, value in values.items()
            if key != "APP_PACKAGE_ID"
        }
        step_outputs["artifact_retention_days"] = str(retention_days)
        print("\n".join(f"{key}={value}" for key, value in step_outputs.items()))
        return
    if output_format == "env":
        print("\n".join(f"{key}={value}" for key, value in values.items()))
        return
    if output_format == "json":
        import json

        print(
            json.dumps(
                {
                    **values,
                    "GIT_REF": build.git_ref,
                    "COMMIT": build.commit,
                    "artifact_retention_days": retention_days,
                },
                indent=2,
            )
        )
        return

    print("Build version")
    print(f"  Source:          {VERSION_FILE.relative_to(ROOT)}")
    print(f"  Channel:         {build.channel}")
    print(f"  Stage:           {build.stage}")
    print(f"  Version:         {build.source.version}")
    print(f"  Semantic version: {build.semantic_version}")
    print(f"  Build number:    {build.build_number}")
    print(f"  Package version: {build.package_version}")
    print(f"  Artifact label:  {build.asset_version}")
    print(f"  Git ref:         {build.git_ref}")
    print(f"  Commit:          {build.commit}")
    print(f"  Artifact retention: {retention_days} days")


def expected_pubspec(source: SourceVersion) -> str:
    return f"version: {source.version}+{source.build_number}"


def sync(check_only: bool) -> None:
    source = read_source()
    expected = expected_pubspec(source)
    content = PUBSPEC_FILE.read_text(encoding="utf-8")
    actual_match = PUBSPEC_PATTERN.search(content)
    actual = actual_match.group(0) if actual_match else "<missing>"
    if actual == expected:
        print(f"pubspec.yaml version is synchronized: {expected}")
        return
    if check_only:
        fail(f"pubspec.yaml version drift: expected '{expected}', got '{actual}'")
    PUBSPEC_FILE.write_text(
        PUBSPEC_PATTERN.sub(expected, content, count=1), encoding="utf-8"
    )
    print(f"Updated pubspec.yaml: {actual} -> {expected}")


def bump(part: str, dry_run: bool) -> None:
    source = read_source()
    major, minor, patch = map(int, source.version.split("."))
    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    elif part == "patch":
        patch += 1
    next_version = source.version if part == "build" else f"{major}.{minor}.{patch}"
    next_source = SourceVersion(next_version, source.build_number + 1)
    print(
        f"Bump {part}: {source.version}+{source.build_number} -> {next_source.version}+{next_source.build_number}"
    )
    if dry_run:
        return
    VERSION_FILE.write_text(
        "# Enmesh release identity. This is the only human-edited application version.\n"
        f"VERSION={next_source.version}\nBUILD_NUMBER={next_source.build_number}\n",
        encoding="utf-8",
    )
    sync(check_only=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve_parser = subparsers.add_parser("resolve", help="resolve a build version")
    resolve_parser.add_argument(
        "--channel", choices=("auto", "production", "canary"), default="auto"
    )
    resolve_parser.add_argument(
        "--format",
        choices=("summary", "env", "github-actions-output", "json"),
        default="summary",
        help=(
            "summary for humans, env for build variables, github-actions-output "
            "for GitHub step outputs, or json for tooling"
        ),
    )

    sync_parser = subparsers.add_parser("sync", help="synchronize pubspec.yaml")
    sync_parser.add_argument(
        "--check", action="store_true", help="fail instead of updating"
    )

    bump_parser = subparsers.add_parser(
        "bump", help="bump the release version and build number"
    )
    bump_parser.add_argument("part", choices=("major", "minor", "patch", "build"))
    bump_parser.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()
    try:
        if args.command == "resolve":
            emit(resolve(args.channel), args.format)
        elif args.command == "sync":
            sync(args.check)
        else:
            bump(args.part, args.dry_run)
    except (OSError, ValueError) as error:
        print(f"version.py: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
