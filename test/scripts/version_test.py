#!/usr/bin/env python3

import importlib.util
import io
import os
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "astral_version", ROOT / "scripts" / "version.py"
)
assert SPEC is not None and SPEC.loader is not None
version = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = version
SPEC.loader.exec_module(version)


class VersionResolutionTest(unittest.TestCase):
    def test_canary_uses_ordered_semver_and_seven_character_commit(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_REF": "refs/pull/12/merge",
                "GITHUB_REF_NAME": "12/merge",
                "GITHUB_RUN_NUMBER": "42",
                "GITHUB_SHA": "abcdef0123456789",
            },
            clear=True,
        ):
            build = version.resolve("canary")

        self.assertEqual(build.commit, "abcdef0")
        self.assertEqual(build.semantic_version, "3.0.0-alpha.42+abcdef0")
        self.assertEqual(build.asset_version, "3.0.0-alpha.42+abcdef0")
        self.assertEqual(build.package_version, "3.0.0~alpha.42+abcdef0")
        self.assertEqual(build.build_number, 1_000_000_042)

    def test_production_uses_release_semver_without_build_metadata(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_ACTIONS": "true",
                "GITHUB_REF": "refs/tags/v3.0.0",
                "GITHUB_REF_NAME": "v3.0.0",
                "GITHUB_SHA": "1234567890abcdef",
            },
            clear=True,
        ):
            build = version.resolve("production")

        self.assertEqual(build.semantic_version, "3.0.0")
        self.assertEqual(build.asset_version, "3.0.0")
        self.assertEqual(build.package_version, "3.0.0")
        self.assertEqual(build.build_number, 10288)

    def test_merged_pull_request_main_push_gets_long_artifact_retention(self):
        self.assertEqual(
            version.artifact_retention_days(
                channel="canary",
                event_name="push",
                git_ref="refs/heads/main",
                commit_subject="[feature] Ship change (#42)",
            ),
            90,
        )

    def test_direct_and_pull_request_builds_keep_short_artifact_retention(self):
        for event_name, git_ref, commit_subject in (
            ("push", "refs/heads/main", "build: refresh dependencies"),
            ("pull_request", "refs/pull/42/merge", "[feature] Ship change (#42)"),
            ("push", "refs/heads/feature/demo", "[feature] Ship change (#42)"),
        ):
            with self.subTest(event_name=event_name, git_ref=git_ref):
                self.assertEqual(
                    version.artifact_retention_days(
                        channel="canary",
                        event_name=event_name,
                        git_ref=git_ref,
                        commit_subject=commit_subject,
                    ),
                    7,
                )

    def test_production_artifacts_keep_release_retention(self):
        self.assertEqual(
            version.artifact_retention_days(
                channel="production",
                event_name="push",
                git_ref="refs/tags/v3.0.0",
                commit_subject="Release 3.0.0",
            ),
            30,
        )

    def test_environment_output_exposes_commit_semver_and_retention(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_REF": "refs/heads/main",
                "GITHUB_REF_NAME": "main",
                "GITHUB_RUN_NUMBER": "7",
                "GITHUB_SHA": "fedcba9876543210",
                "GITHUB_EVENT_NAME": "push",
            },
            clear=True,
        ), patch.object(
            version,
            "git_value",
            return_value="[feature] Ship change (#7)",
        ):
            build = version.resolve("canary")
            output = io.StringIO()
            with redirect_stdout(output):
                version.emit(build, "env")

        values = dict(
            line.split("=", maxsplit=1) for line in output.getvalue().splitlines()
        )
        self.assertEqual(values["BUILD_COMMIT"], "fedcba9")
        self.assertEqual(values["BUILD_RUN_NUMBER"], "7")
        self.assertEqual(values["SEMANTIC_VERSION"], "3.0.0-alpha.7+fedcba9")
        self.assertEqual(values["ASSET_VERSION"], values["SEMANTIC_VERSION"])
        self.assertEqual(values["ARTIFACT_RETENTION_DAYS"], "90")


if __name__ == "__main__":
    unittest.main()
