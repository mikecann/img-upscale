import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO_DIR = pathlib.Path(__file__).resolve().parents[1]


@unittest.skipIf(sys.platform == "win32", "POSIX launcher tests")
class PosixInstallerTests(unittest.TestCase):
    def test_install_is_repeatable_and_launcher_resolves_clone_from_another_directory(self):
        with tempfile.TemporaryDirectory(prefix="img-upscale install ") as temp:
            bin_dir = pathlib.Path(temp) / "bin with spaces"
            for _ in range(2):
                subprocess.run(
                    ["bash", str(REPO_DIR / "install.sh"), str(bin_dir)],
                    cwd=temp,
                    check=True,
                    capture_output=True,
                    text=True,
                )
            launcher = bin_dir / "img-upscale"
            self.assertTrue(launcher.is_symlink())
            self.assertEqual(REPO_DIR / "img-upscale", launcher.resolve())
            result = subprocess.run(
                [str(launcher), "--help"], cwd=temp, capture_output=True, text=True
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("--backend", result.stdout)

    def test_launcher_prefers_clone_virtual_environment_and_preserves_arguments(self):
        with tempfile.TemporaryDirectory(prefix="img-upscale clone ") as temp:
            clone = pathlib.Path(temp)
            shutil.copyfile(REPO_DIR / "img-upscale", clone / "img-upscale")
            python = clone / ".venv" / "bin" / "python3"
            python.parent.mkdir(parents=True)
            # A fake interpreter proves which executable receives the arguments
            # without building another virtual environment or loading any models.
            python.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$@" "$EXEDIR"\n')
            python.chmod(0o755)
            result = subprocess.run(
                ["bash", str(clone / "img-upscale"), "an image.png", "--scale", "4"],
                env={**os.environ, "EXEDIR": str(clone / "external binaries")},
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(
                [str(clone.resolve() / "img-upscale.py"), "an image.png", "--scale", "4",
                 str(clone / "external binaries")],
                result.stdout.splitlines(),
            )

    def test_invalid_option_does_not_install(self):
        result = subprocess.run(
            ["bash", str(REPO_DIR / "install.sh"), "--unknown"],
            capture_output=True, text=True,
        )
        self.assertEqual(1, result.returncode)
        self.assertIn("Usage:", result.stderr)
