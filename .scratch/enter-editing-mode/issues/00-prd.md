---
labels: ready-for-agent
---

# PRD: Enter Editing Mode (Macro Automation)

## Problem Statement
The user needs to manually open, resize, and arrange 6 different applications across 3 uniquely sized monitors (Main landscape, Left vertical, Top landscape) every time they want to start editing videos. This process is repetitive, tedious, and delays the start of the creative workflow. Furthermore, Wallpaper Engine consumes system resources and causes distractions during editing.

## Solution
A single keystroke (the backtick key on the secondary macro keyboard) triggers a LuaMacros sequence (`Shift+F19`) which is caught by a dedicated AutoHotkey script. This script automatically closes Wallpaper Engine, detects the monitor layout dynamically, and precisely launches and positions all required apps (Premiere Pro, OneCommander, Google Docs, ChatGPT, Gemini, and a Brave window with specific tabs) across the 3 monitors in the exact desired layout.

## User Stories
1. As a video editor, I want to press a single macro key on my secondary keyboard, so that my entire 3-monitor editing workspace is automatically configured without manual dragging.
2. As a video editor, I want Wallpaper Engine to close when I enter editing mode, so that I have maximum system resources and zero visual distractions.
3. As a video editor, I want ChatGPT and Gemini PWAs opened on the right half of my main monitor but hidden behind Premiere, so that I can quickly reference them using Alt+Tab.
4. As a video editor, I want a full-screen Brave browser opened with my commonly used tabs (New Tab, Google Images, YouTube, YouTube Music), so that I have immediate access to reference materials and music behind my editor.
5. As a video editor, I want OneCommander to fill exactly the left 60% of my top monitor, so that I have a wide view of my file system.
6. As a video editor, I want Google Docs PWA to fill exactly the right 40% of my top monitor, so that I can read scripts or notes alongside my files.
7. As a video editor, I want Premiere Pro maximized on my main monitor and its secondary panel full-screened on my vertical left monitor, so that I have maximum timeline and playback visibility.

## Implementation Decisions
- **Trigger Layer:** `macro_board.lua` will be modified to listen for the backtick key (button ID 192) and send the `Shift+F19` combination (based on row 68 of the registry).
- **Controller Layer:** `Main_Macro_Board.ahk` will `#Include` the new script to keep the system tray clean.
- **App Layer:** A new script `enter editing mode.ahk` will execute the sequence.
- **Window Positioning:** AHK's `SysGet` will map monitor coordinates. `WinMove` will position OneCommander and Google Docs precisely based on the Top monitor's calculated width (60% and 40%).
- **Premiere Focus:** Because Premiere panels lack distinct AHK-targetable window titles, the script will explicitly move the mouse to the center of the Left monitor and click before sending `Ctrl + \` to guarantee the correct panel is full-screened. The mouse will then be restored.
- **Z-Order:** Background apps (Brave, ChatGPT, Gemini) will be launched *before* Premiere Pro so they naturally fall underneath it in the window stack.

## Testing Decisions
- **Testing Seams:** The script will be logically separated into "monitor boundary calculation" (which takes `SysGet` outputs and returns target X/Y/W/H coordinates) and "window manipulation" (the actual `WinMove` and `Run` commands). This allows us to test if the 40%/60% math is correct based on mock monitor bounds without moving actual windows.
- **Manual Verification (E2E):** Since AHK interacts with real OS windows and timings, the primary test will be a manual E2E run triggering the backtick key from the secondary keyboard and verifying the final layout against the spec.

## Out of Scope
- Opening Google Drive (explicitly deferred by user).
- Managing the state of applications when *exiting* editing mode (this spec only covers entering the mode).

## Further Notes
- PWA shortcut paths are hardcoded to the specific `AppData` Start Menu paths provided by the user.
