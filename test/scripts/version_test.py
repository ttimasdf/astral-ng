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
    def test_pull_request_uses_head_commit_instead_of_merge_commit(self):
        event_path = ROOT / "test-event.json"
        event_path.write_text(
            '{"pull_request":{"title":"修复 Windows 编译 🚀",'
            '"head":{"sha":"1234567890abcdef"}}}'
        )
        try:
            with patch.dict(
                os.environ,
                {
                    "GITHUB_REF": "refs/pull/12/merge",
                    "GITHUB_REF_NAME": "12/merge",
                    "GITHUB_RUN_NUMBER": "42",
                    "GITHUB_SHA": "abcdef0123456789",
                    "GITHUB_EVENT_PATH": str(event_path),
                },
                clear=True,
            ):
                build = version.resolve("canary")
        finally:
            event_path.unlink()

        self.assertEqual(build.commit, "1234567")
        self.assertEqual(build.stage, "alpha")
        self.assertEqual(build.semantic_version, "3.0.0-alpha.42+1234567")
        self.assertEqual(build.asset_version, "3.0.0-alpha.42+1234567")
        self.assertEqual(build.package_version, "3.0.0~alpha.42+1234567")
        self.assertEqual(build.build_number, 1_000_000_042)

    def test_main_push_uses_beta_semver_and_canary_identity(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_REF": "refs/heads/main",
                "GITHUB_REF_NAME": "main",
                "GITHUB_RUN_NUMBER": "43",
                "GITHUB_SHA": "1234567890abcdef",
            },
            clear=True,
        ):
            build = version.resolve("canary")

        self.assertEqual(build.channel, "canary")
        self.assertEqual(build.stage, "beta")
        self.assertEqual(build.semantic_version, "3.0.0-beta.43+1234567")
        self.assertEqual(build.package_version, "3.0.0~beta.43+1234567")
        self.assertTrue(build.is_prerelease)

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

        self.assertEqual(build.stage, "stable")
        self.assertEqual(build.semantic_version, "3.0.0")
        self.assertEqual(build.asset_version, "3.0.0")
        self.assertEqual(build.package_version, "3.0.0")
        self.assertEqual(build.build_number, version.read_source().build_number)
        self.assertFalse(build.is_prerelease)

    def test_rc_tag_uses_signed_production_identity_and_prerelease_semver(self):
        with patch.dict(
            os.environ,
            {
                "GITHUB_ACTIONS": "true",
                "GITHUB_REF": "refs/tags/v3.0.0-rc.2",
                "GITHUB_REF_NAME": "v3.0.0-rc.2",
                "GITHUB_RUN_NUMBER": "91",
                "GITHUB_SHA": "1234567890abcdef",
            },
            clear=True,
        ):
            build = version.resolve("production")

        self.assertEqual(build.channel, "production")
        self.assertEqual(build.stage, "rc")
        self.assertEqual(build.semantic_version, "3.0.0-rc.2")
        self.assertEqual(build.package_version, "3.0.0~rc.2")
        self.assertEqual(build.build_number, version.read_source().build_number)
        self.assertTrue(build.is_prerelease)

    def test_production_rejects_noncanonical_prerelease_tags(self):
        for tag in ("v3.0.0-rc", "v3.0.0-rc.0", "v3.0.0-beta.1", "v3.1.0-rc.1"):
            with self.subTest(tag=tag), patch.dict(
                os.environ,
                {
                    "GITHUB_ACTIONS": "true",
                    "GITHUB_REF": f"refs/tags/{tag}",
                    "GITHUB_REF_NAME": tag,
                },
                clear=True,
            ):
                with self.assertRaises(ValueError):
                    version.resolve("production")

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

    def test_direct_and_pull_request_builds_keep_canary_artifact_retention(self):
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
                    30,
                )

    def test_production_artifacts_keep_release_retention(self):
        self.assertEqual(
            version.artifact_retention_days(
                channel="production",
                event_name="push",
                git_ref="refs/tags/v3.0.0",
                commit_subject="Release 3.0.0",
            ),
            90,
        )

    def test_build_bump_advances_signed_build_number_without_changing_semver(self):
        output = io.StringIO()
        with redirect_stdout(output):
            version.bump("build", dry_run=True)
        source = version.read_source()
        self.assertIn(
            f"{source.version}+{source.build_number} -> "
            f"{source.version}+{source.build_number + 1}",
            output.getvalue(),
        )

    def test_step_outputs_cover_ci_without_redundant_package_id(self):
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
                version.emit(build, "github-actions-output")
            step_values = dict(
                line.split("=", maxsplit=1)
                for line in output.getvalue().splitlines()
            )

        self.assertEqual(
            set(step_values),
            {
                "version_base",
                "build_channel",
                "build_stage",
                "build_commit",
                "build_run_number",
                "semantic_version",
                "flutter_build_name",
                "flutter_build_number",
                "package_version",
                "asset_version",
                "is_prerelease",
                "app_display_name",
                "app_executable",
                "linux_package_name",
                "windows_app_id",
                "artifact_retention_days",
            },
        )
        self.assertEqual(step_values["build_commit"], "fedcba9")
        self.assertEqual(step_values["build_run_number"], "7")
        self.assertEqual(step_values["build_stage"], "beta")
        self.assertEqual(
            step_values["semantic_version"], "3.0.0-beta.7+fedcba9"
        )
        self.assertEqual(step_values["is_prerelease"], "true")
        self.assertEqual(step_values["asset_version"], step_values["semantic_version"])
        self.assertEqual(step_values["app_executable"], "astral-canary")
        self.assertEqual(step_values["artifact_retention_days"], "90")
        self.assertNotIn("app_package_id", step_values)


if __name__ == "__main__":
    unittest.main()
