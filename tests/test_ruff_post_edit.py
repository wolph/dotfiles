from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

REPO_ROOT: Path = Path(__file__).resolve().parents[1]
HANDLER: Path = REPO_ROOT / "bin" / "ruff-post-edit"


class RuffPostEditTests(unittest.TestCase):
    def setUp(self) -> None:
        self._temporary_directory: tempfile.TemporaryDirectory[str] = (
            tempfile.TemporaryDirectory(prefix="ruff-post-edit-test-")
        )
        self.root: Path = Path(self._temporary_directory.name)

    def tearDown(self) -> None:
        self._temporary_directory.cleanup()

    def _run(
        self,
        payload: dict[str, Any],
        *,
        path: str | None = None,
        timeout_seconds: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment: dict[str, str] = dict(os.environ)
        if path is not None:
            environment["PATH"] = path
        if timeout_seconds is not None:
            environment["RUFF_POST_EDIT_TIMEOUT_SECONDS"] = timeout_seconds
        return subprocess.run(
            [sys.executable, str(HANDLER)],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=False,
            env=environment,
            timeout=10,
        )

    def _install_real_ruff(self) -> None:
        ruff_path: str | None = shutil.which("ruff")
        self.assertIsNotNone(ruff_path, "real Ruff is required for integration tests")
        venv_bin: Path = self.root / ".venv" / "bin"
        venv_bin.mkdir(parents=True)
        (venv_bin / "ruff").symlink_to(Path(ruff_path).resolve())
        (self.root / "pyproject.toml").write_text(
            '[tool.ruff]\nline-length = 88\n\n[tool.ruff.lint]\nselect = ["F"]\n',
            encoding="utf-8",
        )

    def test_apply_patch_formats_only_successfully_added_updated_and_moved_python(
        self,
    ) -> None:
        self._install_real_ruff()
        added: Path = self.root / "added file.py"
        added.write_text(
            "import sys\nimport os\n\nVALUE=(os.name,sys.version)\n", encoding="utf-8"
        )
        updated: Path = self.root / "updated.py"
        updated.write_text('RESULT={"answer":1}\n', encoding="utf-8")
        moved: Path = self.root / "moved.py"
        moved.write_text("MOVED=[1,2,3]\n", encoding="utf-8")
        deleted: Path = self.root / "deleted.py"
        deleted.write_text('DELETED={"stay":1}\n', encoding="utf-8")
        text_file: Path = self.root / "notes.txt"
        text_file.write_text('NOT_PYTHON={"stay":1}\n', encoding="utf-8")
        unrelated: Path = self.root / "unrelated.py"
        unrelated.write_text('UNRELATED={"stay":1}\n', encoding="utf-8")
        symlink_target: Path = self.root / "symlink target.py"
        symlink_target.write_text('LINKED={"value":1}\n', encoding="utf-8")
        symlink_path: Path = self.root / "linked.py"
        symlink_path.symlink_to(symlink_target)

        payload: dict[str, Any] = {
            "cwd": str(self.root),
            "hook_event_name": "PostToolUse",
            "tool_name": "apply_patch",
            "tool_input": {
                "command": "\n".join(
                    (
                        "*** Begin Patch",
                        "*** Add File: added file.py",
                        "*** Update File: updated.py",
                        "*** Update File: old.py",
                        "*** Move to: moved.py",
                        "*** Update File: linked.py",
                        "*** Delete File: deleted.py",
                        "*** Update File: notes.txt",
                        "*** End Patch",
                    )
                )
            },
            "tool_response": {"output": "Done!"},
        }

        first: subprocess.CompletedProcess[str] = self._run(payload)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(
            added.read_text(encoding="utf-8"),
            "import os\nimport sys\n\nVALUE = (os.name, sys.version)\n",
        )
        self.assertEqual(
            updated.read_text(encoding="utf-8"), 'RESULT = {"answer": 1}\n'
        )
        self.assertEqual(moved.read_text(encoding="utf-8"), "MOVED = [1, 2, 3]\n")
        self.assertEqual(
            symlink_target.read_text(encoding="utf-8"), 'LINKED = {"value": 1}\n'
        )
        self.assertEqual(deleted.read_text(encoding="utf-8"), 'DELETED={"stay":1}\n')
        self.assertEqual(
            text_file.read_text(encoding="utf-8"), 'NOT_PYTHON={"stay":1}\n'
        )
        self.assertEqual(
            unrelated.read_text(encoding="utf-8"), 'UNRELATED={"stay":1}\n'
        )

        first_contents: dict[Path, str] = {
            path: path.read_text(encoding="utf-8")
            for path in (added, updated, moved, symlink_target)
        }
        second: subprocess.CompletedProcess[str] = self._run(payload)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(
            {
                path: path.read_text(encoding="utf-8")
                for path in (added, updated, moved, symlink_target)
            },
            first_contents,
        )

    def test_claude_edit_aliases_support_relative_and_absolute_paths(self) -> None:
        self._install_real_ruff()
        cases: tuple[tuple[str, str], ...] = (
            ("Edit", "edit.py"),
            ("Write", str(self.root / "write.py")),
            ("MultiEdit", "multi.py"),
        )
        for tool_name, file_path in cases:
            with self.subTest(tool_name=tool_name):
                target: Path = Path(file_path)
                if not target.is_absolute():
                    target = self.root / target
                target.write_text('VALUE={"answer":1}\n', encoding="utf-8")
                result: subprocess.CompletedProcess[str] = self._run(
                    {
                        "cwd": str(self.root),
                        "hook_event_name": "PostToolUse",
                        "tool_name": tool_name,
                        "tool_input": {"file_path": file_path},
                        "tool_response": {"ok": True},
                    }
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(
                    target.read_text(encoding="utf-8"), 'VALUE = {"answer": 1}\n'
                )

    def test_unrelated_failed_deleted_missing_and_non_python_edits_are_no_ops(
        self,
    ) -> None:
        target: Path = self.root / "target.py"
        target.write_text('VALUE={"stay":1}\n', encoding="utf-8")
        payloads: tuple[dict[str, Any], ...] = (
            {
                "cwd": str(self.root),
                "tool_name": "Bash",
                "tool_input": {"command": "touch target.py"},
            },
            {
                "cwd": str(self.root),
                "tool_name": "apply_patch",
                "tool_input": {"command": "*** Delete File: target.py"},
            },
            {
                "cwd": str(self.root),
                "tool_name": "apply_patch",
                "tool_input": {"command": "*** Update File: missing.py"},
            },
            {
                "cwd": str(self.root),
                "tool_name": "apply_patch",
                "tool_input": {"command": "*** Update File: target.py"},
                "tool_response": {"isError": True},
            },
            {
                "cwd": str(self.root),
                "tool_name": "Edit",
                "tool_input": {"file_path": "notes.txt"},
            },
        )
        for payload in payloads:
            with self.subTest(payload=payload):
                result: subprocess.CompletedProcess[str] = self._run(payload, path="")
                self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(target.read_text(encoding="utf-8"), 'VALUE={"stay":1}\n')

    def test_unfixable_lint_is_reported_after_format_still_runs(self) -> None:
        self._install_real_ruff()
        target: Path = self.root / "broken.py"
        target.write_text(
            'print(undefined_name)\nVALUE={"answer":1}\n', encoding="utf-8"
        )
        result: subprocess.CompletedProcess[str] = self._run(
            {
                "cwd": str(self.root),
                "tool_name": "Edit",
                "tool_input": {"file_path": "broken.py"},
                "tool_response": {"ok": True},
            }
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(
            target.read_text(encoding="utf-8"),
            'print(undefined_name)\nVALUE = {"answer": 1}\n',
        )
        self.assertIn("F821", result.stderr)
        self.assertIn("broken.py", result.stderr)

    def test_project_config_cannot_enable_unsafe_fixes(self) -> None:
        self._install_real_ruff()
        (self.root / "pyproject.toml").write_text(
            '[tool.ruff]\nunsafe-fixes = true\n\n[tool.ruff.lint]\nselect = ["F841"]\n',
            encoding="utf-8",
        )
        target: Path = self.root / "unsafe.py"
        target.write_text(
            "def value():\n    discarded = 123\n    return 7\n", encoding="utf-8"
        )
        result: subprocess.CompletedProcess[str] = self._run(
            {
                "cwd": str(self.root),
                "tool_name": "Edit",
                "tool_input": {"file_path": "unsafe.py"},
                "tool_response": {"ok": True},
            }
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(
            target.read_text(encoding="utf-8"),
            "def value():\n    discarded = 123\n    return 7\n",
        )
        self.assertIn("F841", result.stderr)

    def test_project_fix_only_cannot_hide_final_lint_findings(self) -> None:
        self._install_real_ruff()
        (self.root / "pyproject.toml").write_text(
            '[tool.ruff]\nfix-only = true\n\n[tool.ruff.lint]\nselect = ["F"]\n',
            encoding="utf-8",
        )
        target: Path = self.root / "fix_only.py"
        target.write_text(
            'print(undefined_name)\nVALUE={"answer":1}\n', encoding="utf-8"
        )
        result: subprocess.CompletedProcess[str] = self._run(
            {
                "cwd": str(self.root),
                "tool_name": "Edit",
                "tool_input": {"file_path": "fix_only.py"},
                "tool_response": {"ok": True},
            }
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(
            target.read_text(encoding="utf-8"),
            'print(undefined_name)\nVALUE = {"answer": 1}\n',
        )
        self.assertIn("F821", result.stderr)

    def test_missing_ruff_has_actionable_feedback(self) -> None:
        target: Path = self.root / "target.py"
        target.write_text('VALUE={"answer":1}\n', encoding="utf-8")
        result: subprocess.CompletedProcess[str] = self._run(
            {
                "cwd": str(self.root),
                "tool_name": "Edit",
                "tool_input": {"file_path": "target.py"},
                "tool_response": {"ok": True},
            },
            path="",
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Ruff executable not found", result.stderr)
        self.assertIn("target.py", result.stderr)

    def test_ruff_timeout_has_actionable_feedback(self) -> None:
        venv_bin: Path = self.root / ".venv" / "bin"
        venv_bin.mkdir(parents=True)
        fake_ruff: Path = venv_bin / "ruff"
        fake_ruff.write_text("#!/bin/sh\nsleep 2\n", encoding="utf-8")
        fake_ruff.chmod(fake_ruff.stat().st_mode | stat.S_IXUSR)
        target: Path = self.root / "target.py"
        target.write_text('VALUE={"answer":1}\n', encoding="utf-8")
        result: subprocess.CompletedProcess[str] = self._run(
            {
                "cwd": str(self.root),
                "tool_name": "Write",
                "tool_input": {"file_path": "target.py"},
                "tool_response": {"ok": True},
            },
            timeout_seconds="0.05",
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("timed out", result.stderr)
        self.assertIn("target.py", result.stderr)

    def test_invalid_json_has_actionable_feedback(self) -> None:
        result: subprocess.CompletedProcess[str] = subprocess.run(
            [sys.executable, str(HANDLER)],
            input="not-json",
            text=True,
            capture_output=True,
            check=False,
            timeout=10,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid hook JSON", result.stderr)


if __name__ == "__main__":
    unittest.main()
