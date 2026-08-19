#Requires AutoHotkey v2.0
SetWinDelay(0)
SendMode("Event")       ; Event mode handles physically-held modifiers (LWin) reliably
A_MenuMaskKey := "vkE8" ; Extra layer of Start Menu suppression

; ==========================================
; CONFIGURATION & CALIBRATION
; ==========================================

; --- Project Panel: First search result position (screen coords) ---
Global SearchResultX := -1900
Global SearchResultY := -1422

; --- "Insert and overwrite sequences as nests" button (screen coords) ---
; When OFF the pixel is ~#1D1D1D, when ON it's ~#4A4A4A
Global NestToggleX := 55
Global NestToggleY := 261
Global NestToggleOffColor := 0x1D1D1D  ; Color when the option is DISABLED (what we want)
Global NestToggleColorTolerance := 25   ; Tolerance for PixelGetColor comparison

; --- List View icon in Project Panel (screen coords) ---
Global ListViewIconX := -2050
Global ListViewIconY := -1000

; --- Search box clear (X) button position (screen coords) ---
Global SearchClearX := -1796
Global SearchClearY := -1562

; --- Premiere shortcuts ---
Global ShortcutProjectPanel := "+6"     ; Shift+6
Global ShortcutFindBox := "+f"          ; Shift+F
Global ShortcutTimeline := "+8"         ; Shift+8

; --- Drag speed (0 = instant, higher = slower) ---
Global Drag_Speed := 1

; ==========================================
; HELPER: Check if a color is "close enough"
; ==========================================
ColorsAreClose(color1, color2, tolerance) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    return (Abs(r1 - r2) <= tolerance) && (Abs(g1 - g2) <= tolerance) && (Abs(b1 - b2) <= tolerance)
}

; ==========================================
; CORE FUNCTION: SEARCH, DRAG & DROP
; ==========================================
NativeApplyNest(nestName) {
    CoordMode("Mouse", "Screen")
    CoordMode("Pixel", "Screen")
    MouseGetPos(&origX, &origY)

    ; 1. Clean release of modifiers
    Send("{Ctrl up}{Shift up}{Alt up}{LWin up}{RWin up}")

    ; 2. Make sure "Insert and overwrite sequences as nests" is OFF
    pixelColor := PixelGetColor(NestToggleX, NestToggleY)
    if !ColorsAreClose(pixelColor, NestToggleOffColor, NestToggleColorTolerance) {
        MouseMove(NestToggleX, NestToggleY, 0)
        Click()
        Sleep(20)
    }

    ; 3. Focus Project Panel
    Send(ShortcutProjectPanel)
    Sleep(30)

    ; 4. Ensure List View is active
    MouseMove(ListViewIconX, ListViewIconY, 0)
    Click()
    Sleep(20)

    ; 5. Focus Find Box
    Send(ShortcutFindBox)
    Sleep(30)

    ; 6. Paste nest name instantly via clipboard
    A_Clipboard := ""
    A_Clipboard := nestName
    ClipWait(1)          ; Wait until clipboard actually has data (up to 1s)
    Send("^v")
    Sleep(20)
    A_Clipboard := ""    ; Nuke clipboard immediately after paste

    ; 7. Wait for Premiere to filter the bin
    Sleep(220)

    ; 8. Snap to first result and drag to original cursor
    MouseMove(SearchResultX, SearchResultY, 0)
    Sleep(20)
    MouseClickDrag("Left", SearchResultX, SearchResultY, origX, origY, Drag_Speed)
    Sleep(50)

    ; 9. Click the X button next to the search box — no keyboard, no corruption
    MouseMove(SearchClearX, SearchClearY, 0)
    Click()
    Sleep(20)

    ; 10. Focus Timeline
    Send(ShortcutTimeline)
    Sleep(20)

    ; 11. Return mouse to original position
    MouseMove(origX, origY, 0)
}

; ========================================================
; WINDOWS KEY BYPASS (blocks Win key while Premiere is active)
; ========================================================
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")

*LWin:: Return
*RWin:: Return

#HotIf

; ========================================================
; HOTKEY LAYER: LWin + Key (Premiere must be active)
; ========================================================
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe") and GetKeyState("LWin", "P")

*b:: NativeApplyNest("Broll Image Preset Nest")
*c:: NativeApplyNest("Center Bold Text Preset Nest")
*r:: NativeApplyNest("Center Round TextBox Preset Nest")
*t:: NativeApplyNest("Center Typewriter Text Preset Nest")

#HotIf

; ========================================================
; HOTKEY LAYER: LWin + Shift + Key (for shifted combos)
; ========================================================
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe") and GetKeyState("LWin", "P") and GetKeyState("Shift", "P")

*f:: NativeApplyNest("FilmBurn Transition Preset Nest")

#HotIf