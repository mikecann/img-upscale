#!/usr/bin/env bash
# Re-run after moving your clone to update the absolute symlink.
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: bash install.sh [target_bin_dir]"
  echo "Default: ~/.local/bin. Install Python dependencies separately; see README.md."
  exit 0
fi
if [[ $# -gt 1 || "${1:-}" == -* ]]; then
  echo "Usage: bash install.sh [target_bin_dir]" >&2
  exit 1
fi
command -v python3 >/dev/null || { echo "Python 3 is required." >&2; exit 1; }
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$HOME/.local/bin}"
mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/img-upscale"
ln -sf "$REPO_DIR/img-upscale" "$TARGET_DIR/img-upscale"
echo "Installed $TARGET_DIR/img-upscale -> $REPO_DIR/img-upscale"
echo "Add $TARGET_DIR to PATH if needed, then run img-upscale --help."
