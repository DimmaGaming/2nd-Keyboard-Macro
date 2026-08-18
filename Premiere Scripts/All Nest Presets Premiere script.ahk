#Requires AutoHotkey v2.0
SetWinDelay(0)
A_MenuMaskKey := "vkE8" ; Extra layer of Start Menu suppression

; ==========================================
; CONFIGURATION & CALIBRATION 
; ==========================================
Global ProjectResultX := 300 
Global ProjectResultY := 500  

Global ShortcutProjectPanel := "+1"    
Global ShortcutFindBox := "^f"         

Global Drag_Speed := 2

; ==========================================
; CORE FUNCTION: HYPER-OPTIMIZED DRAG & DROP
; ==========================================
NativeApplyNest(nestName) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&origX, &origY)

    ; 1. Clean release of normal modifiers
    Send("{Ctrl up}{Shift up}{Alt up}") 

    ; 2. Instantly focus Project Panel & clear search
    Send(ShortcutProjectPanel)
    Sleep(40)
    Send(ShortcutFindBox)
    Sleep(40)
    
    ; Combining Ctrl+A and Backspace for faster execution
    Send("^a{Backspace}")
    Sleep(20)

    ; 3. Type nest name
    SendText(nestName)
    
    ; 🚨 CRITICAL WAIT: Premiere takes ~100ms to filter the project bin. 
    ; If we go faster than 120ms, it will drag the wrong file. This guarantees 0 glitches.
    Sleep(120) 

    ; 4. Glide to the result and drag
    MouseMove(ProjectResultX, ProjectResultY, 0)
    Sleep(20)
    MouseClickDrag("Left", ProjectResultX, ProjectResultY, origX, origY, Drag_Speed)
    Sleep(30) ; Gives Premiere the frame it needs to drop the clip

    ; 5. Instantly clean the search box so the panel is ready for manual use
    Send(ShortcutProjectPanel)
    Sleep(30)
    Send(ShortcutFindBox)
    Sleep(30)
    Send("^a{Backspace}")
    Sleep(20)

    ; 6. Return mouse instantly
    MouseMove(origX, origY, 0)
}

; ========================================================
; THE ZERO-GLITCH WINDOWS KEY BYPASS
; ========================================================
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe")

; 1. Nuke the Windows Key. The OS will never see you press it. No Start Menu, ever.
*LWin::Return
*RWin::Return

#HotIf

; 2. Create a custom layer that ONLY activates when the physical hardware switch is held
#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe") and GetKeyState("LWin", "P")

*q::NativeApplyNest("01_MAIN_TEXT_NEST")
*w::NativeApplyNest("02_ADJUSTMENT_LAYER_NEST")
*e::NativeApplyNest("03_SOME_OTHER_NEST")
*a::NativeApplyNest("04_SOME_OTHER_NEST")
*s::NativeApplyNest("05_SOME_OTHER_NEST")
*d::NativeApplyNest("06_SOME_OTHER_NEST")

#HotIf