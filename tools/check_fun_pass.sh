#!/bin/bash
set -euo pipefail

# All checks write saves. Always copy the project and use a separate profile.
project_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
qa_project="$(mktemp -d /tmp/hackerquest-fun-qa.XXXXXX)"
trap 'rm -rf "$qa_project"' EXIT
rsync -a --exclude=.git --exclude=.godot --exclude=.claude --exclude=docs/qa \
  "$project_root/" "$qa_project/"
python3 - "$qa_project/project.godot" <<'PY'
import pathlib
import sys
path = pathlib.Path(sys.argv[1])
source = path.read_text().replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="HackerQuest-Fun-QA"', 1)
path.write_text(source)
PY

"$godot_bin" --headless --path "$qa_project" --import > /tmp/hackerquest-import.log 2>&1
"$godot_bin" --headless --path "$qa_project" res://tests/smoke_test.tscn > /tmp/hackerquest-smoke.log 2>&1
"$godot_bin" --headless --path "$qa_project" --script res://tests/street_cache_test.gd > /tmp/hackerquest-cache.log 2>&1
"$godot_bin" --headless --path "$qa_project" --script res://tests/modern_ui_test.gd > /tmp/hackerquest-modern-ui.log 2>&1
if [[ "${1:-}" == "--preview" ]]; then
  "$godot_bin" --path "$qa_project" --rendering-method mobile --audio-driver Dummy \
    --script res://tests/fun_pass_preview.gd > /tmp/hackerquest-preview.log 2>&1
  "$godot_bin" --path "$qa_project" --rendering-method mobile --audio-driver Dummy \
    --script res://tests/modern_ui_preview.gd > /tmp/hackerquest-ui-captures.log 2>&1
fi
cat /tmp/hackerquest-smoke.log /tmp/hackerquest-cache.log /tmp/hackerquest-modern-ui.log
if [[ "${1:-}" == "--preview" ]]; then
  cat /tmp/hackerquest-preview.log /tmp/hackerquest-ui-captures.log
fi
# Godot can exit successfully after a script error; treat those as failures.
if rg -n 'SCRIPT ERROR|Parse Error|FAIL:' /tmp/hackerquest-import.log /tmp/hackerquest-smoke.log /tmp/hackerquest-cache.log /tmp/hackerquest-modern-ui.log; then
  exit 1
fi
if [[ "${1:-}" == "--preview" ]] && rg -n 'SCRIPT ERROR|Parse Error|FAIL:' /tmp/hackerquest-preview.log /tmp/hackerquest-ui-captures.log; then
  exit 1
fi
