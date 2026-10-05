#!/usr/bin/env python3
"""Validate the supported mise profiles and environment overlays."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

try:
    import tomllib
except ModuleNotFoundError:
    raise SystemExit("Python 3.11+ is required for TOML validation") from None

TEMPLATES = Path(__file__).resolve().parents[1] / "templates" / "mise"
PROFILES = ("gradle", "maven", "go", "python", "typescript")
MISE = shutil.which("mise")


@unittest.skipUnless(MISE, "mise is required for runtime template tests")
class MiseTemplates(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="mise-templates-")
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.project = root / "project"
        self.project.mkdir()
        self.env = {
            "PATH": f"{Path(MISE).parent}:/usr/bin:/bin",
            "HOME": str(root),
            "MISE_CONFIG_DIR": str(root / "config"),
            "MISE_DATA_DIR": str(root / "data"),
            "MISE_CACHE_DIR": str(root / "cache"),
            "MISE_STATE_DIR": str(root / "state"),
            "MISE_GLOBAL_CONFIG_FILE": str(root / "global.toml"),
            "MISE_SYSTEM_CONFIG_FILE": str(root / "system.toml"),
            "MISE_CEILING_PATHS": str(self.project),
            "MISE_TRUSTED_CONFIG_PATHS": str(self.project),
            "MISE_AUTO_INSTALL": "0",
            "MISE_NOT_FOUND_AUTO_INSTALL": "0",
            "MISE_COLOR": "0",
        }

    def load(self, profile="gradle"):
        tomllib.loads((TEMPLATES / profile / "mise.toml.example").read_text())
        (self.project / "mise.toml").write_text('min_version = "2026.9.18"\n[env]\nAPP_ENV = "local"\n')
        for name in ("mise.dev.toml", "mise.prod.toml"):
            path = TEMPLATES / "common" / f"{name}.example"
            tomllib.loads(path.read_text())
            (self.project / name).write_text(path.read_text())

    def mise(self, *args, success=True, extra_env=None):
        result = subprocess.run([MISE, *args], cwd=self.project, env=self.env | (extra_env or {}), capture_output=True, text=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0, result.stderr + result.stdout)
        return result

    def test_profiles_parse_and_tasks_validate(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                self.load(profile)
                self.mise("tasks", "validate", "--errors-only")

    def test_environment_selection_and_required_secret(self):
        self.load()
        for args, expected in (((), "local"), (("-E", "dev"), "dev"), (("-E", "prod"), "prod")):
            result = self.mise(*args, "exec", "--", "sh", "-c", 'printf "%s" "$APP_ENV"')
            self.assertEqual(result.stdout, expected)
        prod = self.project / "mise.prod.toml"
        prod.write_text(prod.read_text() + 'DATABASE_URL = { required = true, redact = true }\n')
        self.mise("-E", "prod", "exec", "--", "true", success=False)
        self.mise("-E", "prod", "exec", "--", "true", extra_env={"DATABASE_URL": "fixture-only"})


if __name__ == "__main__":
    if not MISE:
        raise SystemExit("mise is required; no runtime checks were run")
    unittest.main(verbosity=2)
