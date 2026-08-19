#Requires AutoHotkey v2.0

; ============================================================
; ENTER EDITING MODE
; Triggered by: Shift+F19 (backtick on secondary macro keyboard)
; ============================================================
; Architecture notes (see PRD §Implementation Decisions):
;   - Background apps (Brave, ChatGPT, Gemini) are launched FIRST
;     so they naturally sit behind Premiere in the Z-order.
;   - Monitor geometry is resolved once via _GetMonitorBounds()
;     and reused throughout, keeping positioning logic testable.
; ============================================================

; ------------------------------------
; HOTKEY ENTRY POINT
; ------------------------------------
; Backtick on macro board sends Ctrl+Shift+Alt+F23 via LuaMacros.
; Uses the same physical-modifier multiplexing pattern as the arrow keys:
;   - Backtick alone          → Enter Editing Mode
;   - Ctrl (main KB) + Backtick → Exit Editing Mode
*^+!F23:: {
    if GetKeyState("Ctrl", "P")
        ExitEditingMode()
    else
        EnterEditingMode()
}

; ------------------------------------
; PURE COORDINATE HELPERS (testable seam)
; ------------------------------------

/**
 * Returns a Map of {x, y, w, h} for a given monitor index.
 * Wraps SysGet so positioning logic can be unit-tested with
 * mock values without moving real windows.
 */
_GetMonitorBounds(monitorIndex) {
    MonitorGet monitorIndex, &ml, &mt, &mr, &mb
    return Map(
        "x", ml,
        "y", mt,
        "w", mr - ml,
        "h", mb - mt
    )
}

/**
 * Given a monitor bounds Map, returns the {x,y,w,h} for the
 * right half of that monitor (used for ChatGPT & Gemini).
 * 
 * Compensates for Windows DWM invisible borders (~7px on left/right/bottom).
 * Without this, WinMove leaves a visible gap at the screen edge because the
 * invisible border "eats" pixels from the window's visible area.
 */
_RightHalf(bounds) {
    static BORDER := 7   ; DWM invisible border thickness (Win 10/11 standard)
    halfW := bounds["w"] // 2
    return Map(
        "x", bounds["x"] + halfW - BORDER,
        "y", bounds["y"],
        "w", bounds["w"] - halfW + BORDER * 2,
        "h", bounds["h"] + BORDER
    )
}

/**
 * Returns the {x,y,w,h} for the left 50% of a monitor.
 * Height is reduced to 85% (anchored to top) for OneCommander.
 * Used for OneCommander on the Top monitor.
 * 
 * DWM border compensation: extends left edge by BORDER and adds BORDER to width
 * so the visible area fills exactly the left half.
 */
_LeftHalf(bounds) {
    sixtyW := Round(bounds["w"] * 0.60)
    sixtyH := Round(bounds["h"] * 0.60)
    return Map(
        "x", bounds["x"],
        "y", bounds["y"],
        "w", sixtyW,
        "h", sixtyH
    )
}

/**
 * Returns the {x,y,w,h} for the right 40% of a monitor.
 * Used for Google Docs PWA on the Top monitor.
 * 
 * Re-added DWM border compensation (7px) specifically for Chrome PWAs. 
 * This expands the window's mathematical boundaries by 7px so its *visible* 
 * edge aligns pixel-perfectly with OneCommander at the 60% mark.
 */
_RightHalfTop(bounds) {
    BORDER := 7
    sixtyW := Round(bounds["w"] * 0.60)
    fortyW := bounds["w"] - sixtyW
    return Map(
        "x", bounds["x"] + sixtyW - BORDER,
        "y", bounds["y"],
        "w", fortyW + BORDER * 2,
        "h", bounds["h"] + BORDER
    )
}

; ------------------------------------
; MONITOR LAYOUT DETECTION
; ------------------------------------

/**
 * Detects the three monitor roles dynamically by their geometry:
 *   Main      — the primary monitor (contains virtual origin 0,0)
 *   Left      — the vertical monitor (portrait: height > width)
 *   Top       — the secondary landscape monitor
 * 
 * Returns a Map: { "main": <idx>, "left": <idx>, "top": <idx> }
 */
_DetectMonitorRoles() {
    monCount := MonitorGetCount()
    mainIdx := MonitorGetPrimary()
    leftIdx := 0
    topIdx := 0

    loop monCount {
        if (A_Index == mainIdx)
            continue
        MonitorGet A_Index, &ml, &mt, &mr, &mb
        w := mr - ml
        h := mb - mt
        if (h > w)          ; portrait orientation → Left vertical monitor
            leftIdx := A_Index
        else                ; landscape → Top monitor
            topIdx := A_Index
    }

    return Map("main", mainIdx, "left", leftIdx, "top", topIdx)
}

; ------------------------------------
; APP MANAGEMENT & CLEANUP
; ------------------------------------

/**
 * Closes every visible app gracefully, hitting Enter if a save dialog appears.
 */
_CloseAllApps() {
    DetectHiddenWindows False
    idList := WinGetList()

    for hwnd in idList {
        try {
            if !WinExist("ahk_id " hwnd)
                continue

            title := WinGetTitle("ahk_id " hwnd)
            class := WinGetClass("ahk_id " hwnd)
            exe := WinGetProcessName("ahk_id " hwnd)

            ; Exclude empty titles and desktop/taskbar elements
            if (title == "" || class == "Progman" || class == "WorkerW" || class == "Shell_TrayWnd" || class == "Windows.UI.Core.CoreWindow")
                continue

            ; Exclude Antigravity
            if InStr(title, "Antigravity")
                continue

            ; Exclude Rainmeter and Wallpaper Engine from WM_CLOSE
            ; (Sending WinClose to their background windows causes them to open their UIs)
            if (exe == "Rainmeter.exe" || InStr(exe, "wallpaper"))
                continue

            ; Exclude the script itself
            if (hwnd == A_ScriptHwnd)
                continue

            ; Graceful close request - if it doesn't close, we leave it alone.
            WinClose("ahk_id " hwnd)
        }
    }
}

/**
 * Launches Background Apps (Wallpaper Engine, Rainmeter)
 */
_LaunchBackgroundApps() {
    ; ── Launch Rainmeter ──────────────────────────────────────────
    ToolTip("Step 1/7: Launching Rainmeter...")
    if !ProcessExist("Rainmeter.exe") {
        Run '"C:\Program Files\Rainmeter\Rainmeter.exe"'

        ; Auto-dismiss the Safe Start dialog if it appears from a previous crash.
        ; The default button is "Yes", so we send Right Arrow to highlight "No", then Enter.
        if WinWait("Rainmeter Safe Start", , 3) {
            WinActivate("Rainmeter Safe Start")
            WinWaitActive("Rainmeter Safe Start", , 1)
            Send "{Right}{Enter}"
        }
    }

    if !ProcessExist("wallpaper64.exe") && !ProcessExist("wallpaper32.exe") {
        Run '"C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\wallpaper64.exe" -control quiet', , "Hide"
    }
}

/**
 * Closes Wallpaper Engine and Rainmeter gracefully.
 * Handles both 32-bit and 64-bit Wallpaper Engine process names.
 * 
 * Rainmeter NOTE: ProcessClose("Rainmeter.exe") kills the process but its tray
 * watchdog immediately respawns it — same as Task Manager kill. Instead we send
 * the !Quit bang via Rainmeter's own CLI, which is equivalent to right-click
 * tray → Exit and shuts the whole session down permanently.
 */
_CloseBackgroundApps() {
    ; Rainmeter's !Quit bang cleanly shuts down the main instance, preventing Safe Start.
    ; However, the bang-sender process sometimes gets stuck. We give the main instance
    ; 1 second to save its state, then we force kill any remaining stuck processes.
    if ProcessExist("Rainmeter.exe") {
        Run '"C:\Program Files\Rainmeter\Rainmeter.exe" !Quit'
        Sleep 1000
        while ProcessExist("Rainmeter.exe") {
            ProcessClose("Rainmeter.exe")
        }
    }

    ; Force kill Wallpaper Engine to actually kill the desktop wallpaper,
    ; then edit its config to suppress the Safe Mode crash dialog on next launch.
    for exeName in ["wallpaper32.exe", "wallpaper64.exe"] {
        if ProcessExist(exeName) {
            ProcessClose(exeName)
            ProcessWaitClose(exeName, 3)

            configFile := "C:\Program Files (x86)\Steam\steamapps\common\wallpaper_engine\config.json"
            if FileExist(configFile) {
                configText := FileRead(configFile)
                configText := StrReplace(configText, '"safemode" : true', '"safemode" : false')
                FileDelete(configFile)
                FileAppend(configText, configFile)
            }
        }
    }
}

; ------------------------------------
; APP LAUNCH HELPERS
; ------------------------------------

/**
 * Launches the ChatGPT PWA and positions it on the right half
 * of the main monitor (sits behind Premiere, reachable via Alt+Tab).
 */
_LaunchChatGPT(rightHalf) {
    chatgptPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Brave Apps\ChatGPT.lnk"
    Run chatgptPath
    if WinWait("ChatGPT", , 10) {
        WinActivate("ChatGPT")
        WinWaitActive("ChatGPT", , 5)
        WinMove(rightHalf["x"], rightHalf["y"], rightHalf["w"], rightHalf["h"], "ChatGPT")
    }
}

/**
 * Launches the Gemini PWA and positions it on the right half
 * of the main monitor.
 */
_LaunchGemini(rightHalf) {
    geminiPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Gemini.lnk"
    if !FileExist(geminiPath)
        geminiPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Brave Apps\Google Gemini.lnk"

    Run geminiPath
    if WinWait("Gemini", , 10) {
        WinActivate("Gemini")
        WinWaitActive("Gemini", , 5)
        WinMove(rightHalf["x"], rightHalf["y"], rightHalf["w"], rightHalf["h"], "Gemini")
    }
}

/**
 * Opens a clean Brave window with exactly these 5 tabs, maximised on the main monitor.
 */
_LaunchBrave(mainBounds) {
    bravePath := "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"

    Run '"' bravePath '"'

    if !WinWait("ahk_exe brave.exe", , 10)
        return
    WinActivate("ahk_exe brave.exe")
    WinWaitActive("ahk_exe brave.exe", , 5)
    WinMove(mainBounds["x"], mainBounds["y"], mainBounds["w"], mainBounds["h"], "ahk_exe brave.exe")
    WinMaximize("ahk_exe brave.exe")
}

_LaunchOneCommander(leftHalf) {
    ocExe := "C:\Program Files\OneCommander\OneCommander.exe"

    ; Give OneCommander a moment to finish its graceful close from _CloseAllApps
    if WinExist("ahk_exe OneCommander.exe") {
        WinWaitClose("ahk_exe OneCommander.exe", , 2)
    }

    ; We completely avoid ProcessClose (force kill). Force killing causes OneCommander
    ; to perform a slow "crash recovery" on next launch, taking several seconds.
    ; If it's still somehow lingering gracefully ask again:
    if WinExist("ahk_exe OneCommander.exe") {
        try WinClose("ahk_exe OneCommander.exe")
        WinWaitClose("ahk_exe OneCommander.exe", , 1)
    }

    Run '"' ocExe '"'

    if !WinWait("ahk_exe OneCommander.exe", , 15)
        return

    WinActivate("ahk_exe OneCommander.exe")
    WinWaitActive("ahk_exe OneCommander.exe", , 5)
    ; OneCommander has a small splash screen. We loop until a large enough
    ; window exists, guaranteeing we have the main UI before we move it.
    ocTick := A_TickCount
    loop {
        try {
            WinGetPos(&x, &y, &w, &h, "ahk_exe OneCommander.exe")
            if (h > 300)
                break
        }
        if (A_TickCount - ocTick > 10000)
            break
        Sleep 50
    }

    WinRestore("ahk_exe OneCommander.exe")
    WinMove(leftHalf["x"], leftHalf["y"], leftHalf["w"], leftHalf["h"], "ahk_exe OneCommander.exe")
}

/**
 * Launches the Google Docs (DocsDark) PWA and snaps it to the right 50%
 * of the Top monitor.
 */
_LaunchGoogleDocs(rightHalfTop) {
    docsPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Brave Apps\DocsDark - Google.lnk"
    Run docsPath
    if WinWait("Google Docs", , 10) {
        WinActivate("Google Docs")
        WinWaitActive("Google Docs", , 5)
        WinRestore("Google Docs")
        WinMove(rightHalfTop["x"], rightHalfTop["y"], rightHalfTop["w"], rightHalfTop["h"], "Google Docs")
    }
}

/**
 * Launches or activates Premiere Pro, maximises it on the Main monitor,
 * then full-screens its secondary panel on the Left monitor.
 * 
 * Strategy (see PRD §Implementation Decisions):
 *   1. Run Premiere (RunWait-style: Run then WinWait).
 *   2. Maximise on Main monitor.
 *   3. Save current mouse coords.
 *   4. Move mouse to centre of Left monitor and left-click to focus the panel.
 *   5. Send Ctrl+\ to toggle full-screen for the focused panel.
 *   6. Restore mouse to saved position.
 */
_LaunchPremiere(mainBounds, leftBounds) {
    ; ── Launch / activate Premiere ────────────────────────────────
    premiereExe := "Adobe Premiere Pro.exe"
    projectPath := "D:\Dimma\Editing\Raw\Video Editing Assets\Editing Template\NEW Editing Template\Editing Template 2026.prproj"

    ; Open the project file directly — Premiere will launch if not already running,
    ; or load the project into the existing instance.
    if !ProcessExist(premiereExe)
        Run '"' projectPath '"'

    ; Wait up to 15 s for the main Premiere window (title contains "Adobe Premiere Pro")
    if !WinWait("Adobe Premiere Pro", , 15)
        return   ; could not open Premiere — abort gracefully

    ; ── Guard: detect Adobe license/error dialog ──────────────────
    ; If Adobe shows a "too many users" or sign-in dialog, ABORT.
    ; Continuing would blindly send clicks/keys and corrupt the UI.
    Sleep 1000   ; give dialogs a moment to appear
    if WinExist("ahk_class #32770 ahk_exe Adobe Premiere Pro.exe")
        return   ; Adobe dialog detected — hands off
    if WinExist("Sign in ahk_exe Adobe Premiere Pro.exe")
        return
    ; Also check for generic Adobe pop-up titles
    if WinExist("Adobe Premiere Pro ahk_class #32770")
        return

    ; ── Guard: verify the project actually loaded ─────────────────
    ; Premiere's main application window uniquely uses "ahk_class Premiere Pro".
    ; Floating toolbars and panels use "DroverLord", so this class is bulletproof.
    mainPremiereTitle := "ahk_class Premiere Pro ahk_exe Adobe Premiere Pro.exe"

    if !WinWait(mainPremiereTitle, , 30)
        return

    WinActivate(mainPremiereTitle)
    WinWaitActive(mainPremiereTitle, , 5)

    ; ── Focus Left-monitor panel & full-screen it ─────────────────
    ; Save current mouse position so we can restore it afterwards
    MouseGetPos(&savedX, &savedY)

    ; Calculate the centre of the Left monitor
    leftCX := leftBounds["x"] + leftBounds["w"] // 2
    leftCY := leftBounds["y"] + leftBounds["h"] // 2

    ; Move to centre of Left monitor and click to give focus to that Premiere panel
    MouseMove(leftCX, leftCY, 0)   ; 0 = instant (no animation)
    Click()
    Sleep 150

    ; Send Ctrl+\ to toggle full-screen on the focused panel
    Send "^\\"   ; AHK syntax: ^ = Ctrl, \\ = literal backslash
    Sleep 150

    ; Restore mouse to where it was before
    MouseMove(savedX, savedY, 0)
}

; ------------------------------------
; MAIN ORCHESTRATOR
; ------------------------------------

_OpenOneCommanderTabs() {
    static ocFolders := [
        "C:\Users\Dimma2ndProfile\Downloads",
        "D:\Dimma\Editing\Client Work",
        "D:\Dimma\Editing\Raw\Video Editing Assets\Editing Template\NEW Editing Template",
        "D:\Dimma\Editing\Raw\Video Editing Assets\Sound Effects"
    ]

    if !WinExist("ahk_exe OneCommander.exe")
        return

    WinActivate("ahk_exe OneCommander.exe")
    if !WinWaitActive("ahk_exe OneCommander.exe", , 5)
        return

    ; Open tabs via keyboard automation
    for idx, folder in ocFolders {
        if (idx > 1) {
            Send "^t"  ; New tab
            Sleep 100
        }
        Send "!d"  ; Focus address bar
        Sleep 50
        oldClip := A_Clipboard
        A_Clipboard := folder
        Sleep 50
        Send "^v"
        Sleep 50
        Send "{Enter}"
        Sleep 100
        A_Clipboard := oldClip
    }
}

EnterEditingMode() {
    ToolTip("Step 1/7: Closing all existing apps...")
    _CloseAllApps()

    ToolTip("Step 2/7: Closing background apps...")
    _CloseBackgroundApps()

    ToolTip("Step 3/7: Launching Brave...")
    roles := _DetectMonitorRoles()
    mainBounds := _GetMonitorBounds(roles["main"])
    rightHalf := _RightHalf(mainBounds)

    _LaunchBrave(mainBounds)

    ToolTip("Step 4/7: Launching Gemini and ChatGPT...")
    _LaunchGemini(rightHalf)
    _LaunchChatGPT(rightHalf)

    ToolTip("Step 5/7: Launching OneCommander & Docs...")
    topBounds := _GetMonitorBounds(roles["top"])
    leftHalf := _LeftHalf(topBounds)
    rightHalfTop := _RightHalfTop(topBounds)

    _LaunchOneCommander(leftHalf)
    _LaunchGoogleDocs(rightHalfTop)

    ToolTip("Step 6/7: Launching Premiere Pro...")
    leftBounds := _GetMonitorBounds(roles["left"])
    _LaunchPremiere(mainBounds, leftBounds)

    ToolTip("Step 7/7: Opening OneCommander Tabs...")
    _OpenOneCommanderTabs()

    ; --- BRING PREMIERE TO FRONT ---
    ; Explicitly activate Premiere again at the very end to guarantee it
    ; sits in front of Brave and ChatGPT in the Z-order.
    if WinExist("ahk_class Premiere Pro ahk_exe Adobe Premiere Pro.exe") {
        WinActivate("ahk_class Premiere Pro ahk_exe Adobe Premiere Pro.exe")
    }

    ToolTip() ; Clear tooltip when finished
}

ExitEditingMode() {
    ToolTip("Closing all foreground apps...")
    _CloseAllApps()

    ToolTip("Launching Wallpaper Engine & Rainmeter...")
    _LaunchBackgroundApps()

    ToolTip()
}