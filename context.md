# Project Context: Macro Board & Premiere Scripts

## Overview
This project uses a combination of LuaMacros and AutoHotkey (AHK v2) to create a custom macro keyboard setup tailored for video editing in Adobe Premiere Pro and general productivity. It intercepts keystrokes from a secondary keyboard and translates them into complex shortcuts and automated actions.

## Core Architecture

### 1. The Hardware Interceptor: `macro_board.lua`
- **Tool used:** LuaMacros
- **Function:** Listens to a specific secondary keyboard (device `2B6D316` named 'MACRO_BOARD').
- **Mechanism:** It intercepts physical keystrokes and maps them to obscure function key combinations (e.g., F19-F24, `Ctrl+Shift+Alt+F13-F18`). This prevents the secondary keyboard from interfering with normal typing on the primary keyboard.
- **Categories of Macros:**
  - **Split-Key Holds (Raw F-Keys):** Maps keys like Pause, Scroll Lock, Home, Page Up to raw F-keys (F19-F22) on key down, and sends F24 on key up. This is useful for holding down a modifier for actions like Position, Scale, or Rotation.
  - **Standard Macros (Taps):** Maps specific keys to complex combinations like `Ctrl+Shift+Alt+F13` for App Switching/Premiere Macros and `Ctrl+Shift+F13` for Project Panel Nest Droppers.

### 2. The Main Controller: `Main_Macro_Board.ahk`
- **Tool used:** AutoHotkey v2
- **Function:** Serves as the central hub and execution engine. It sets global behaviors (like permanently disabling CapsLock) and defines a master reload hotkey (`Ctrl+Alt+R` in Notepad).
- **Structure:** Instead of running multiple independent AHK scripts, it uses `#Include` to load all other specialized scripts into a single running instance. This keeps the system tray clean and manages all hotkeys centrally to avoid conflicts.
- **Included Files:**
  - `Premiere Scripts\Clipboard Paste Into Timeline.ahk`
  - `Premiere Scripts\Black Arrow Keys Application Switch & Slide Effects.ahk`
  - `Premiere Scripts\All Effects Apply Script.ahk`
  - `Premiere Scripts\All Premiere Functions Added.ahk`
  - `Premiere Scripts\All Nest Presets Premiere script.ahk`

### 3. Feature Modules (The "Premiere Scripts" Folder)
This directory houses the individual AHK scripts that define the actual actions triggered by the LuaMacros combinations.

#### `Clipboard Paste Into Timeline.ahk` (and Python helper)
- **Goal:** Rapidly take an image copied to the clipboard and drop it into the Premiere Pro timeline without manual file management.
- **Workflow:**
  1. Triggered by `Ctrl+Shift+Alt+F17` (which is mapped to a physical key via LuaMacros).
  2. Runs a Python script (`Clipboard Paste Into Timeline Python Script.py`).
  3. The Python script uses `PIL` (Pillow) to grab the current clipboard image, convert it to a `.png`, and save it with a timestamp in a designated folder (`D:\Dimma\Editing\All Editing Images Folder`).
  4. The AHK script waits for the new file to appear on the hard drive.
  5. It quickly brings up the Windows Explorer window for that folder, navigates to the file, and simulates a mouse click-and-hold on the new image.
  6. It swiftly swaps focus back to Premiere Pro and releases the mouse, effectively dragging and dropping the newly saved image directly into the timeline.
- **Bonus Feature:** Includes a specialized hotkey (`Ctrl+Shift+Alt+F18`) that only triggers when Brave Browser is active, performing a fast "Right-Click -> Copy Image" (using the "y" shortcut in the context menu).

#### Other Included Scripts
- **`Black Arrow Keys Application Switch & Slide Effects.ahk`**: Handles application window switching and applying specific slide effects in Premiere.
- **`All Effects Apply Script.ahk`**: Automates the application of various effects within Premiere.
- **`All Premiere Functions Added.ahk`**: Contains miscellaneous automated Premiere functions.
- **`All Nest Presets Premiere script.ahk`**: Handles dropping nests and presets from the Project Panel (likely triggered by the `Ctrl+Shift+Fxx` combinations defined in LuaMacros).

## Summary
The system provides a highly efficient, automated pipeline:
**Physical Key Press (2nd Keyboard)  ->  LuaMacros intercepts and sends complex F-Key Combination  ->  AutoHotkey Main Hub catches the combo  ->  Specific Module Script executes the action  ->  Result achieved in Premiere Pro (or OS).**

This decouples the physical hardware from the software actions, allowing for an incredibly flexible, powerful, and fast video editing workflow.
