#!/usr/bin/env bash
# install.sh - set up claude-code-statusline on macOS / Linux.
# Run from a clone:  ./install.sh
# Or one-liner:      curl -fsSL https://gitlab.com/spiegel/claude-code-statusline/-/raw/main/install.sh | bash
set -e

cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$cfg"
dest="$cfg/statusline.sh"

# Use the local script if running from a clone, otherwise download it.
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$here" ] && [ -f "$here/statusline.sh" ]; then
  cp "$here/statusline.sh" "$dest"
else
  curl -fsSL "https://gitlab.com/spiegel/claude-code-statusline/-/raw/main/statusline.sh" -o "$dest"
fi
chmod +x "$dest"

# Merge the statusLine entry into settings.json (keeping existing settings).
settings="$cfg/settings.json"
cmd="bash \"$dest\""
if command -v python3 >/dev/null 2>&1; then
  python3 - "$settings" "$cmd" <<'PY'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f: data = json.load(f)
    except Exception:
        data = {}
data["statusLine"] = {"type": "command", "command": cmd}
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PY
else
  echo "python3 not found - add this to $settings yourself:"
  echo "  \"statusLine\": { \"type\": \"command\", \"command\": \"$cmd\" }"
fi

echo "Installed -> $dest"
echo "Restart Claude Code (or open a new session) to see the status line."
