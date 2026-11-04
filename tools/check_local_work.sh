#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
qa_project="$(mktemp -d /tmp/hackerquest-work-qa.XXXXXX)"
trap 'rm -rf "$qa_project"' EXIT
rsync -a --exclude=.git --exclude=.godot --exclude=.claude --exclude=docs/qa "$project_root/" "$qa_project/"
python3 - "$qa_project/project.godot" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="HackerQuest-Work-QA"', 1))
PY
"$godot_bin" --headless --path "$qa_project" --import > /tmp/hackerquest-work-import.log 2>&1
"$godot_bin" --headless --path "$qa_project" --script res://tests/local_work_test.gd > /tmp/hackerquest-work-test.log 2>&1
cat /tmp/hackerquest-work-test.log
if [[ "${1:-}" == "--preview" ]]; then
  "$godot_bin" --path "$qa_project" --rendering-method mobile --audio-driver Dummy --script res://tests/local_work_preview.gd > /tmp/hackerquest-work-preview.log 2>&1
  cat /tmp/hackerquest-work-preview.log
fi
if rg -n 'SCRIPT ERROR|Parse Error|FAIL:' /tmp/hackerquest-work-import.log /tmp/hackerquest-work-test.log; then exit 1; fi
if [[ "${1:-}" == "--preview" ]] && rg -n 'SCRIPT ERROR|Parse Error|FAIL:' /tmp/hackerquest-work-preview.log; then exit 1; fi
