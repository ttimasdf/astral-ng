#!/usr/bin/env python3

from __future__ import annotations

import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).parents[2] / "scripts" / "diagnostic_jsonl.py"
SPEC = importlib.util.spec_from_file_location("diagnostic_jsonl", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
diagnostic_jsonl = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic_jsonl)


def record(timestamp: str, sequence: int, code: str | None = None) -> dict:
    event = {
        "created": timestamp,
        "sequence": sequence,
        "provider": "rust",
    }
    if code is not None:
        event["code"] = code
    return {
        "@timestamp": timestamp,
        "ecs.version": "8.11.0",
        "message": "Diagnostic event",
        "log.level": "info",
        "log": {"logger": "astral.easytier"},
        "event": event,
        "service": {"name": "astral-ng"},
        "session": {"id": "SESSION"},
        "astral": {
            "schema_version": 3,
            "ingest_sequence": sequence,
            "classification": "upstream-unclassified",
        },
    }


class DiagnosticJsonlTest(unittest.TestCase):
    def test_accepts_semantic_and_unclassified_ecs_records(self) -> None:
        semantic = record("2026-01-01T00:00:00.000Z", 1, "easytier.peer.added")
        unclassified = record("2026-01-01T00:00:01.000Z", 2)

        self.assertEqual(
            diagnostic_jsonl.validate_record(semantic, "semantic")["event"]["code"],
            "easytier.peer.added",
        )
        self.assertNotIn(
            "code",
            diagnostic_jsonl.validate_record(unclassified, "unclassified")["event"],
        )

    def test_rejects_source_location_as_event_code(self) -> None:
        invalid = record(
            "2026-01-01T00:00:00.000Z",
            1,
            "rust.event@easytier:connector/manual.rs:213",
        )

        with self.assertRaisesRegex(
            diagnostic_jsonl.DiagnosticError,
            "not semantic event codes",
        ):
            diagnostic_jsonl.validate_record(invalid, "invalid")

    def test_merge_sorts_rotations_by_source_timestamp(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = pathlib.Path(temporary)
            newer = record("2026-01-01T00:00:02.000Z", 2)
            older = record("2026-01-01T00:00:01.000Z", 1)
            (directory / "astral.jsonl").write_text(
                json.dumps(newer) + "\n",
                encoding="utf-8",
            )
            (directory / "astral.jsonl.1").write_text(
                json.dumps(older) + "\n",
                encoding="utf-8",
            )

            records = diagnostic_jsonl.read_records(
                diagnostic_jsonl.paths_from_arguments([str(directory)])
            )
            records.sort(key=diagnostic_jsonl.record_sort_key)

            self.assertEqual(
                [item["astral"]["ingest_sequence"] for item in records],
                [1, 2],
            )

    def test_rejects_ansi_sequences(self) -> None:
        invalid = copy.deepcopy(record("2026-01-01T00:00:00.000Z", 1))
        invalid["message"] = "\u001b[31mfailed\u001b[0m"

        with self.assertRaisesRegex(diagnostic_jsonl.DiagnosticError, "ANSI"):
            diagnostic_jsonl.validate_record(invalid, "invalid")


if __name__ == "__main__":
    unittest.main()
