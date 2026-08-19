#Requires AutoHotkey v2.0
SendMode("Input")
SetWinDelay(0) ; Fixes the app switching slowness

; ==========================================
; BRAVE WINDOW GROUPING & EXCLUSIONS
; ==========================================
SetTitleMatchMode(2) ; Sets standard match mode as the global default

; Group contains all Brave apps, excluding ChatGPT OR Gemini.
GroupAdd("BraveWindows", "ahk_exe brave.exe",, "ChatGPT|Gemini")

; ==========================================
; HELPER FUNCTIONS
; ==========================================
ApplyArrowEffect(effectName) {
    EffectResultX := 3300 
    EffectResultY := 350  
    EffCtrlMidX := -1900   
    EffCtrlMidY := 1300    
    ShortcutEffectsPanel := "+3"
    ShortcutEffectControls := "+2"
    ShortcutFindBox := "+f"
    UI_Wait := 200
    Drag_Speed := 3

    Sleep(50) 
    Send("{Ctrl up}{Alt up}{Shift up}") 
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&origX, &origY)

    Send(ShortcutEffectsPanel)
    Sleep(UI_Wait)
    Send("{Esc}") 
    Sleep(30)
    Send(ShortcutFindBox) 
    Sleep(UI_Wait)

    Send("^a")
    Sleep(30)
    Send("{Backspace}")
    Sleep(30)

    SendText(effectName)
    Sleep(UI_Wait * 2)

    MouseMove(EffectResultX, EffectResultY, 0)
    Sleep(40)
    MouseClickDrag("Left", EffectResultX, EffectResultY, origX, origY, Drag_Speed)
    Sleep(UI_Wait)

    ; --- CLEANUP PHASE ---
    Send(ShortcutEffectsPanel)
    Sleep(UI_Wait)
    Send("{Esc}") 
    Sleep(30)
    Send(ShortcutFindBox)
    Sleep(UI_Wait)
    
    Send("^a") 
    Sleep(30)
    Send("{Backspace}")
    Sleep(30)
    Send("{Enter}") ; COMMIT the empty box so Premiere doesn't restore the text
    Sleep(30)
    Send("{Esc}")   ; DROP text focus cleanly
    Sleep(UI_Wait)

    Send(ShortcutEffectControls)
}

LaunchViaFlow(appName) {
    Sleep(50) 
    Send("{Ctrl up}{Alt up}{Shift up}") 
    Sleep(50) 

    Send("!{Space}") 
    Sleep(150) 
    SendText(appName)
    Sleep(200) 
    Send("{Enter}")
}

; ==========================================
; MACRO BOARD ARROWS: Left (^ + Shift + Alt + F13) - AI Apps ONLY
; ==========================================
*^+!F13::
{
    static db13 := 0
    if (A_TickCount - db13 < 250)
        return
    db13 := A_TickCount

    if GetKeyState("CapsLock", "P") and WinActive("ahk_exe Adobe Premiere Pro.exe") {
        if GetKeyState("Shift", "P")
            ApplyArrowEffect("Slide Out Left")
        else
            ApplyArrowEffect("Slide In Left")
    } else {
        if WinActive("ChatGPT") {
            if WinExist("Gemini")
                WinActivate("Gemini")
            else
                LaunchViaFlow("Gemin") 
        } else if WinActive("Gemini") {
            if WinExist("ChatGPT")
                WinActivate("ChatGPT")
            else
                LaunchViaFlow("ChatGP")
        } else {
            if WinExist("ChatGPT")
                WinActivate("ChatGPT")
            else if WinExist("Gemini")
                WinActivate("Gemini")
            else
                LaunchViaFlow("ChatGP")
        }
    }
}

; ==========================================
; MACRO BOARD ARROWS: Up (^ + Shift + Alt + F14) - Premiere
; ==========================================
*^+!F14::
{
    static db14 := 0
    if (A_TickCount - db14 < 250)
        return
    db14 := A_TickCount

    if GetKeyState("CapsLock", "P") and WinActive("ahk_exe Adobe Premiere Pro.exe") {
        if GetKeyState("Shift", "P")
            ApplyArrowEffect("Slide Out Up")
        else
            ApplyArrowEffect("Slide In Up")
    } else {
        if WinExist("ahk_exe Adobe Premiere Pro.exe")
            WinActivate()
        else
            Run('"C:\Program Files\Adobe\Adobe Premiere Pro 2026\Adobe Premiere Pro.exe"')
    }
}

; ==========================================
; MACRO BOARD ARROWS: Right (^ + Shift + Alt + F15) - Brave/Docs ONLY
; ==========================================
*^+!F15::
{
    static db15 := 0
    if (A_TickCount - db15 < 250)
        return
    db15 := A_TickCount

    if GetKeyState("CapsLock", "P") and WinActive("ahk_exe Adobe Premiere Pro.exe") {
        if GetKeyState("Shift", "P")
            ApplyArrowEffect("Slide Out Right")
        else
            ApplyArrowEffect("Slide In Right")
    } else {
        ; MUST temporarily enable RegEx mode here so GroupActivate parses the | as an OR exclusion
        SetTitleMatchMode("RegEx") 
        
        if WinExist("ahk_group BraveWindows")
            GroupActivate("BraveWindows", "R")
        else
            Run("brave.exe")
            
        SetTitleMatchMode(2) ; Return thread to standard match mode
    }
}

; ==========================================
; MACRO BOARD ARROWS: Down (^ + Shift + Alt + F16) - OneCommander
; ==========================================
*^+!F16::
{
    static db16 := 0
    if (A_TickCount - db16 < 250)
        return
    db16 := A_TickCount

    if GetKeyState("CapsLock", "P") and WinActive("ahk_exe Adobe Premiere Pro.exe") {
        if GetKeyState("Shift", "P")
            ApplyArrowEffect("Slide Out Down")
        else
            ApplyArrowEffect("Slide In Down")
    } else {
        if WinExist("ahk_exe OneCommander.exe")
            WinActivate()
        else
            Run('"C:\Program Files\OneCommander\OneCommander.exe"')
    }
}