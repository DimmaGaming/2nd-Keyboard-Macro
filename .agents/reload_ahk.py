"""
reload_ahk.py
Restarts the AHK script after a file edit.
Called automatically by the IDE hook (hooks.json) after every file save.

Uses AutoHotkey's built-in /restart flag — no Notepad, no key simulation,
no interference with other apps like Premiere Pro.
"""

import subprocess
import sys
import json
import os

AHK_EXE = r"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
SCRIPT   = r"D:\Dimma\Coding Workflow\AutoHotKey Scripts\Main_Macro_Board.ahk"

# Drain stdin (IDE sends JSON context — we don't need it but must read it)
try:
    _ = json.load(sys.stdin)
except Exception:
    pass

# Bail out if AutoHotkey exe isn't found
if not os.path.exists(AHK_EXE):
    # Try alternate install paths
    for candidate in [
        r"C:\Program Files\AutoHotkey\AutoHotkey.exe",
        r"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe",
        r"C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe",
    ]:
        if os.path.exists(candidate):
            AHK_EXE = candidate
            break
    else:
        print(f"ERROR: AutoHotkey exe not found. Tried {AHK_EXE!r}", file=sys.stderr)
        print("{}")   # required by hooks contract
        sys.exit(0)

result = subprocess.run(
    [AHK_EXE, "/restart", SCRIPT],
    capture_output=True,
    text=True,
)

if result.returncode != 0:
    print(f"AHK reload failed: {result.stderr}", file=sys.stderr)

# PostToolUse hooks must output an empty JSON object
print("{}")
