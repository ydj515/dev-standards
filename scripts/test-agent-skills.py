#!/usr/bin/env python3
"""Exercise skill distribution without invoking or installing an AI client."""

import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE = Path(__file__).resolve().parent.parent
AGENTS = ("codex", "claude", "gemini")


class AgentSkillDistributionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.output = self.root / ".dev-standards"
        self.output.mkdir()
        self.config = self.output / "config.yml"
        self.config.write_text("version: 1\nbase: false\nlanguages: [java]\n")

    def compose(self, source=SOURCE):
        return subprocess.run(
            [
                "bash", str(SOURCE / "scripts/compose.sh"),
                "--source", str(source),
                "--config", str(self.config),
                "--output", str(self.output / "styleguide.md"),
                "--modules-dir", str(self.output / "standards"),
            ],
            capture_output=True, text=True,
        )

    def test_complete_bundles_and_project_files_preserved(self):
        existing = {
            "AGENTS.md": "# Local rules\n",
            ".codex/config.toml": 'model = "project-model"\n',
            ".claude/settings.json": '{"permissions": {}}\n',
            ".gemini/settings.json": '{"context": {"fileName": "PROJECT.md"}}\n',
            ".agents/skills/custom/SKILL.md": "# Custom skill\n",
        }
        for relative, content in existing.items():
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        result = self.compose()
        self.assertEqual(result.returncode, 0, result.stderr)
        for agent in AGENTS:
            skill = self.output / agent / "skills" / "merge-dev-standards"
            self.assertEqual(
                (skill / "SKILL.md").read_bytes(),
                (SOURCE / "templates/agent-skills/SKILL.md").read_bytes(),
            )
            self.assertEqual(
                (skill / "references/merge-rules.md").read_bytes(),
                (SOURCE / "templates/agent-skills/references/merge-rules.md").read_bytes(),
            )
            self.assertIn("name: merge-dev-standards\n", (skill / "SKILL.md").read_text())
            self.assertEqual(
                (skill / "assets/worktreeinclude").read_bytes(),
                (SOURCE / "templates/agent-skills/assets/worktreeinclude").read_bytes(),
            )
            self.assertEqual(
                (skill / "assets/AGENTS.md").read_bytes(),
                (SOURCE / "templates/agents/AGENTS.md").read_bytes(),
            )
            for target in AGENTS:
                self.assertEqual(
                    (skill / "references" / f"{target}.md").read_bytes(),
                    (SOURCE / "templates/agent-skills/references" / f"{target}.md").read_bytes(),
                )
        for relative, content in existing.items():
            self.assertEqual((self.root / relative).read_text(), content)
        self.assertFalse((self.root / ".claude/rules").exists())
        self.assertFalse((self.root / ".gemini/skills").exists())
        self.assertFalse((self.root / ".agents/skills/merge-dev-standards").exists())
        self.assertFalse((self.root / ".worktreeinclude").exists())

    def test_each_bundle_is_self_contained_when_other_distributions_are_absent(self):
        self.assertEqual(self.compose().returncode, 0)
        import re
        import shutil

        for agent in AGENTS:
            isolated = self.root / f"isolated-{agent}"
            bundle = self.output / agent / "skills/merge-dev-standards"
            shutil.copytree(bundle, isolated)
            for document in isolated.rglob("*.md"):
                for link in re.findall(r"\]\(([^)]+)\)", document.read_text()):
                    resolved = (document.parent / link).resolve()
                    self.assertTrue(resolved.is_relative_to(isolated.resolve()))
                    self.assertTrue(resolved.is_file(), link)
            self.assertEqual(len(list(isolated.rglob("*.md"))), 6)

    def test_repeat_is_unchanged_and_managed_content_refreshes(self):
        self.assertEqual(self.compose().returncode, 0)
        files = [p for agent in AGENTS for p in (self.output / agent).rglob("*") if p.is_file()]
        before = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in files}
        self.assertEqual(self.compose().returncode, 0)
        self.assertEqual(before, {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in files})
        files[0].write_text("stale managed distribution")
        custom = self.output / "codex/notes.md"
        custom.write_text("keep custom sibling")
        self.assertEqual(self.compose().returncode, 0)
        self.assertEqual(files[0].read_bytes(), before[files[0]][0])
        self.assertEqual(custom.read_text(), "keep custom sibling")

    def test_symlink_rejected_before_any_bundle_is_written(self):
        outside = self.root / "outside"
        outside.mkdir()
        (outside / "keep.md").write_text("keep")
        (self.output / "gemini").symlink_to(outside, target_is_directory=True)
        result = self.compose()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symbolic link", result.stderr)
        self.assertFalse((self.output / "codex").exists())
        self.assertFalse((self.output / "claude").exists())
        self.assertEqual(list(outside.iterdir()), [outside / "keep.md"])

    def test_incompatible_parent_rejected_before_any_bundle_is_written(self):
        (self.output / "claude").write_text("project file")
        result = self.compose()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("incompatible agent skill destination", result.stderr)
        self.assertFalse((self.output / "codex").exists())
        self.assertEqual((self.output / "claude").read_text(), "project file")

    def test_standards_only_source_remains_supported(self):
        source = self.root / "external-source"
        (source / "standards/languages").mkdir(parents=True)
        (source / "standards/languages/java.md").write_text("# External Java rules\n")
        result = self.compose(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("skipping skill distribution", result.stderr)
        self.assertIn("External Java rules", (self.output / "styleguide.md").read_text())
        self.assertFalse((self.output / "codex").exists())


if __name__ == "__main__":
    unittest.main()
