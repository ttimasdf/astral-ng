#!/usr/bin/env python3
"""Resolve, validate, synchronize, and bump Astral-ng application versions."""

from __future__ import annotations

import argparse
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
PUBSPEC_PATTERN = re.compile(r"^version: .*$", re.MULTILINE)
CANARY_BUILD_OFFSET = 1_000_000_000
ANDROID_VERSION_CODE_LIMIT = 2_147_483_647


@dataclass(frozen=True)
class SourceVersion:
    version: str
    build_number: int


@dataclass(frozen=True)
class BuildVersion:
    source: SourceVersion
    channel: str
    build_number: int
    asset_version: str
    git_ref: str
    commit: str

    @property
    def package_version(self) -> str:
        return f"{self.source.version}.{self.build_number}"


def fail(message: str) -> None:
    raise ValueError(message)


def git_value(*args: str, fallback: str) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(ROOT), *args], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return fallback


def read_source() -> SourceVersion:
    values: dict[str, str] = {}
    for line in VERSION_FILE.read_text().splitlines():
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

    commit = os.getenv("GITHUB_SHA", "")[:12] or git_value(
        "rev-parse", "--short=12", "HEAD", fallback="local"
    )
    git_ref = github_ref_name or git_value("branch", "--show-current", fallback="detached")

    if channel == "production":
        tag = github_ref_name or github_ref.removeprefix("refs/tags/")
        if os.getenv("GITHUB_ACTIONS") and tag != f"v{source.version}":
            fail(f"Production tag must be v{source.version}; got {tag or '<none>'}")
        return BuildVersion(source, channel, source.build_number, f"v{source.version}", git_ref, commit)

    if channel == "canary":
        try:
            run_number = int(os.getenv("GITHUB_RUN_NUMBER", "0"))
        except ValueError:
            fail("GITHUB_RUN_NUMBER must be numeric")
        if run_number < 0:
            fail("GITHUB_RUN_NUMBER must not be negative")
        build_number = CANARY_BUILD_OFFSET + run_number
        if build_number > ANDROID_VERSION_CODE_LIMIT:
            fail("Canary build number exceeds Android's versionCode limit")
        return BuildVersion(
            source,
            channel,
            build_number,
            f"v{source.version}-canary.{run_number}-{commit}",
            git_ref,
            commit,
        )

    fail("Channel must be auto, production, or canary")


def emit(build: BuildVersion, output_format: str) -> None:
    values = {
        "VERSION_BASE": build.source.version,
        "BUILD_CHANNEL": build.channel,
        "FLUTTER_BUILD_NAME": build.source.version,
        "FLUTTER_BUILD_NUMBER": str(build.build_number),
        "PACKAGE_VERSION": build.package_version,
        "ASSET_VERSION": build.asset_version,
    }
    if output_format == "env":
        print("\n".join(f"{key}={value}" for key, value in values.items()))
        return
    if output_format == "json":
        import json

        print(json.dumps({**values, "GIT_REF": build.git_ref, "COMMIT": build.commit}, indent=2))
        return

    print("Build version")
    print(f"  Source:          {VERSION_FILE.relative_to(ROOT)}")
    print(f"  Channel:         {build.channel}")
    print(f"  Version:         {build.source.version}")
    print(f"  Build number:    {build.build_number}")
    print(f"  Package version: {build.package_version}")
    print(f"  Artifact label:  {build.asset_version}")
    print(f"  Git ref:         {build.git_ref}")
    print(f"  Commit:          {build.commit}")


def expected_pubspec(source: SourceVersion) -> str:
    return f"version: {source.version}+{source.build_number}"


def sync(check_only: bool) -> None:
    source = read_source()
    expected = expected_pubspec(source)
    content = PUBSPEC_FILE.read_text()
    actual_match = PUBSPEC_PATTERN.search(content)
    actual = actual_match.group(0) if actual_match else "<missing>"
    if actual == expected:
        print(f"pubspec.yaml version is synchronized: {expected}")
        return
    if check_only:
        fail(f"pubspec.yaml version drift: expected '{expected}', got '{actual}'")
    PUBSPEC_FILE.write_text(PUBSPEC_PATTERN.sub(expected, content, count=1))
    print(f"Updated pubspec.yaml: {actual} -> {expected}")


def bump(part: str, dry_run: bool) -> None:
    source = read_source()
    major, minor, patch = map(int, source.version.split("."))
    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    else:
        patch += 1
    next_source = SourceVersion(f"{major}.{minor}.{patch}", source.build_number + 1)
    print(f"Bump {part}: {source.version}+{source.build_number} -> {next_source.version}+{next_source.build_number}")
    if dry_run:
        return
    VERSION_FILE.write_text(
        "# Astral-ng release identity. This is the only human-edited application version.\n"
        f"VERSION={next_source.version}\nBUILD_NUMBER={next_source.build_number}\n"
    )
    sync(check_only=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    resolve_parser = subparsers.add_parser("resolve", help="resolve a build version")
    resolve_parser.add_argument("--channel", choices=("auto", "production", "canary"), default="auto")
    resolve_parser.add_argument("--format", choices=("summary", "env", "json"), default="summary")

    sync_parser = subparsers.add_parser("sync", help="synchronize pubspec.yaml")
    sync_parser.add_argument("--check", action="store_true", help="fail instead of updating")

    bump_parser = subparsers.add_parser("bump", help="bump the release version and build number")
    bump_parser.add_argument("part", choices=("major", "minor", "patch"))
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
