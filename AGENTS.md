# Agent guidance for img-upscale

This is a standalone Python CLI for Windows and macOS. All source and launchers
live at the repo root. The quality backend uses progressive Swin2SR 2x steps;
the optional fast backend uses Real-ESRGAN ncnn Vulkan.

## Development rules

- Use test-first development for non-trivial changes. If there is no clean test
  seam, extract one and add a test before changing behaviour.
- When behaviour changes, update the affected expectations and rerun the tests.
- Before committing, run `python3 -m unittest discover -s tests -v` (Windows:
  `python -m unittest discover -s tests -v`), then smoke-test the actual launcher.
  Tensor tests need torch, numpy and Pillow, but never download a model.
- Run `pwsh -NoProfile -File tests/test_installers.ps1` for icon, stub and
  shared-menu helper tests. Registry calls are mocked; they don't replace a real
  Windows install/uninstall smoke test.
- Parse every `.ps1` with PowerShell's
  `[System.Management.Automation.Language.Parser]::ParseFile`. Run Windows
  installer checks on Windows, where registry and PATH behaviour can be verified.
- Keep `.bat` files ASCII; generated stubs use `-Encoding ASCII`.
- Never copy source into `C:\dev\tools`. `install.ps1` creates thin stubs that
  forward to this clone. Editing source needs no reinstall; moving the clone does.
- Large binaries stay outside this repo, normally in `C:\dev\tools` on Windows.
  Never commit `.exe`, `.dll` or model files. Respect `EXEDIR` for the fast backend,
  falling back to the script directory when it is unset.
- This CLI intentionally uses a console for prompts. It is not a GUI/taskbar app.
- Preserve other tools' verbs in the shared Explorer "Mike's Tools" submenu.
  Uninstallation may remove only `ImgUpscale` and this tool's generated files.
- On macOS, `install.sh` symlinks the launcher into `~/.local/bin` by default.
  The launcher resolves symlinks to locate this clone.
- Both launchers prefer this clone's `.venv` interpreter when present. Keep
  `deps.ps1` pointed at the same interpreter as the Windows launcher.

## Dependency setup

`deps.ps1` must be idempotent, self-contained and runnable directly. Check Python
modules before installing missing packages with `python -m pip`. Use clear,
coloured output. Check for Python with `Get-Command` and fail clearly if absent.
Large manual-download binaries should only produce a helpful check/message.
`install.ps1` runs `deps.ps1` unless `-SkipDeps` is passed.

Keep dependency setup in sync with `requirements.txt`. No API keys or `.env` are
needed. Keep CI CPU-only, without model downloads or secrets.
