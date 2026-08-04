#!/usr/bin/env python3
"""Validate, merge, and retrieve Astral's canonical diagnostic JSONL."""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import subprocess
import sys
from collections.abc import Iterable, Sequence
from typing import Any

ANSI_ESCAPE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")
PACKAGE_NAME = re.compile(r"^[A-Za-z0-9._]+$")
REQUIRED_LEVELS = {"trace", "debug", "info", "warning", "error", "fatal"}
ROTATED_NAMES = ("astral.jsonl.2", "astral.jsonl.1", "astral.jsonl")


class DiagnosticError(Exception):
    pass


def _object(value: Any, name: str, location: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise DiagnosticError(f"{location}: {name} must be a JSON object")
    return value


def validate_record(record: Any, location: str) -> dict[str, Any]:
    item = _object(record, "record", location)
    for key in ("@timestamp", "ecs.version", "message"):
        if not isinstance(item.get(key), str) or not item[key]:
            raise DiagnosticError(f"{location}: missing non-empty {key}")

    log = _object(item.get("log"), "log", location)
    if item.get("log.level") not in REQUIRED_LEVELS:
        raise DiagnosticError(f"{location}: invalid log.level")
    if not isinstance(log.get("logger"), str) or not log["logger"]:
        raise DiagnosticError(f"{location}: missing log.logger")

    event = _object(item.get("event"), "event", location)
    if not isinstance(event.get("created"), str) or not event["created"]:
        raise DiagnosticError(f"{location}: missing event.created")
    if not isinstance(event.get("provider"), str) or not event["provider"]:
        raise DiagnosticError(f"{location}: missing event.provider")
    if not isinstance(event.get("sequence"), int):
        raise DiagnosticError(f"{location}: event.sequence must be an integer")
    if "code" in event and (not isinstance(event["code"], str) or not event["code"]):
        raise DiagnosticError(f"{location}: event.code must be non-empty when present")
    if str(event.get("code", "")).startswith("rust.event@"):
        raise DiagnosticError(f"{location}: source locations are not semantic event codes")

    astral = _object(item.get("astral"), "astral", location)
    if not isinstance(astral.get("schema_version"), int):
        raise DiagnosticError(f"{location}: missing astral.schema_version")
    if not isinstance(astral.get("ingest_sequence"), int):
        raise DiagnosticError(f"{location}: missing astral.ingest_sequence")

    if contains_ansi(item):
        raise DiagnosticError(f"{location}: ANSI escape sequence is not allowed")
    return item


def contains_ansi(value: Any) -> bool:
    if isinstance(value, str):
        return ANSI_ESCAPE.search(value) is not None
    if isinstance(value, dict):
        return any(contains_ansi(key) or contains_ansi(item) for key, item in value.items())
    if isinstance(value, list):
        return any(contains_ansi(item) for item in value)
    return False


def read_records(paths: Iterable[pathlib.Path]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for path in paths:
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError as error:
            raise DiagnosticError(f"{path}: {error}") from error
        for line_number, line in enumerate(lines, 1):
            if not line.strip():
                continue
            location = f"{path}:{line_number}"
            try:
                decoded = json.loads(line)
            except json.JSONDecodeError as error:
                raise DiagnosticError(f"{location}: invalid JSON: {error.msg}") from error
            records.append(validate_record(decoded, location))
    return records


def record_sort_key(record: dict[str, Any]) -> tuple[Any, ...]:
    astral = record["astral"]
    session = record.get("session")
    session_id = session.get("id", "") if isinstance(session, dict) else ""
    return (
        record["@timestamp"],
        record["event"]["created"],
        session_id,
        astral["ingest_sequence"],
    )


def write_records(records: Iterable[dict[str, Any]], output: pathlib.Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="\n") as stream:
        for record in records:
            stream.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")))
            stream.write("\n")


def print_summary(records: Sequence[dict[str, Any]]) -> None:
    origins = collections.Counter(record["event"]["provider"] for record in records)
    semantic = sum("code" in record["event"] for record in records)
    print(f"records={len(records)} semantic={semantic} unclassified={len(records) - semantic}")
    if origins:
        print("origins=" + ",".join(f"{key}:{origins[key]}" for key in sorted(origins)))


def adb_base(device: str | None) -> list[str]:
    command = ["adb"]
    if device:
        command.extend(("-s", device))
    return command


def pull_android(package: str, device: str | None) -> list[dict[str, Any]]:
    if not PACKAGE_NAME.fullmatch(package):
        raise DiagnosticError("Android package name contains unsupported characters")
    records: list[dict[str, Any]] = []
    for name in ROTATED_NAMES:
        remote = f"files/logs/{name}"
        probe = subprocess.run(
            [*adb_base(device), "shell", "run-as", package, "test", "-f", remote],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if probe.returncode != 0:
            continue
        fetched = subprocess.run(
            [*adb_base(device), "exec-out", "run-as", package, "cat", remote],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if fetched.returncode != 0:
            detail = fetched.stderr.decode("utf-8", errors="replace").strip()
            raise DiagnosticError(f"failed to read {remote}: {detail}")
        for line_number, raw_line in enumerate(fetched.stdout.splitlines(), 1):
            if not raw_line.strip():
                continue
            location = f"android:{remote}:{line_number}"
            try:
                decoded = json.loads(raw_line)
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                raise DiagnosticError(f"{location}: invalid JSON: {error}") from error
            records.append(validate_record(decoded, location))
    if not records:
        raise DiagnosticError(
            "no diagnostic JSONL was readable; use a debuggable package or the in-app export"
        )
    return records


def paths_from_arguments(values: Sequence[str]) -> list[pathlib.Path]:
    paths: list[pathlib.Path] = []
    for value in values:
        path = pathlib.Path(value)
        if path.is_dir():
            paths.extend(path / name for name in ROTATED_NAMES if (path / name).is_file())
        else:
            paths.append(path)
    if not paths:
        raise DiagnosticError("no input files were found")
    return paths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    validate = subparsers.add_parser("validate", help="validate ECS/Astral JSONL")
    validate.add_argument("paths", nargs="+", help="JSONL files or log directories")

    merge = subparsers.add_parser("merge", help="merge and chronologically sort JSONL")
    merge.add_argument("paths", nargs="+", help="JSONL files or log directories")
    merge.add_argument("-o", "--output", required=True, type=pathlib.Path)

    pull = subparsers.add_parser("pull-android", help="pull private logs with adb run-as")
    pull.add_argument("-p", "--package", default="pw.rabit.astralng.canary")
    pull.add_argument("-s", "--device")
    pull.add_argument("-o", "--output", required=True, type=pathlib.Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "pull-android":
            records = pull_android(args.package, args.device)
            records.sort(key=record_sort_key)
            write_records(records, args.output)
        else:
            records = read_records(paths_from_arguments(args.paths))
            records.sort(key=record_sort_key)
            if args.command == "merge":
                write_records(records, args.output)
        print_summary(records)
        return 0
    except DiagnosticError as error:
        print(f"diagnostic-jsonl: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
