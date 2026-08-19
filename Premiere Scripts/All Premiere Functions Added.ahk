#Requires AutoHotkey v2.0
SetWinDelay(0)
CoordMode("Mouse", "Screen")
SendMode("Event")

; ==========================================
; PROPERTIES PANEL EXACT COORDINATES
; ==========================================
Global PosX_X := -1380
Global PosX_Y := 840

Global PosY_X := -1250
Global PosY_Y := 840

Global Scale_X := -1376
Global Scale_Y := 953

Global Rot_X := -1388
Global Rot_Y := 1009

; ==========================================
; UNIVERSAL RELEASE TRIGGER (F24)
; ==========================================
Global MacroReleased := false

*F24:: {
    Global MacroReleased := true
}

; ==========================================
; PREMIERE PRO SPECIFIC MACROS
; ==========================================
#HotIf WinActive("ahk_class Premiere Pro")

F8:: {
    MouseGetPos(&mouseX, &mouseY)
    A_Clipboard := mouseX ", " mouseY
    ToolTip("Copied: " A_Clipboard)
    SetTimer(() => ToolTip(), -2000)
}

$3:: {
    if !KeyWait("3", "T0.25") {
        Send("33")
        KeyWait("3")
    } else {
        Send("3")
    }
}

; ---------------------------------------------------------
; VALUE DRAG: SCALE (Pause Key -> F19)
; ---------------------------------------------------------
*F19:: {
    Global MacroReleased := false
    MouseGetPos(&origX, &origY)

    Click() ; Selects the clip under the cursor
    Sleep(50)

    Send("{Shift down}1{Shift up}") ; Focus Properties Panel
    Sleep(150)

    MouseMove(Scale_X, Scale_Y, 0)
    Click("Down")
    Sleep(150)

    ; --- TAP DETECTED ---
    if (MacroReleased) {
        Click("Up")
        Sleep(50)
        SendText("100")
        Sleep(50)
        Send("{Enter}")
        Sleep(50)
        MouseMove(origX, origY, 0)
        Sleep(50)
        Click() ; Clicks timeline to regain focus
        return
    }

    ; --- HOLD DETECTED ---
    MouseMove(Scale_X + 10, Scale_Y, 2)
    while (!MacroReleased) {
        Sleep(10)
    }

    Click("Up")
    MouseMove(origX, origY, 0)
    Sleep(50)
    Click() ; Clicks timeline to regain focus
}

; ---------------------------------------------------------
; VALUE DRAG: POSITION X (Scroll Lock -> F20)
; ---------------------------------------------------------
*F20:: {
    Global MacroReleased := false
    MouseGetPos(&origX, &origY)

    Click() ; Selects the clip under the cursor
    Sleep(50)

    Send("{Shift down}1{Shift up}")
    Sleep(150)

    MouseMove(PosX_X, PosX_Y, 0)
    Click("Down")
    Sleep(150)

    ; --- TAP DETECTED ---
    if (MacroReleased) {
        Click("Up")
        Sleep(50)
        SendText("960")
        Sleep(50)
        Send("{Enter}")
        Sleep(50)
        MouseMove(origX, origY, 0)
        Sleep(50)
        Click()
        return
    }

    ; --- HOLD DETECTED ---
    MouseMove(PosX_X + 10, PosX_Y, 2)
    while (!MacroReleased) {
        Sleep(10)
    }

    Click("Up")
    MouseMove(origX, origY, 0)
    Sleep(50)
    Click()
}

; ---------------------------------------------------------
; VALUE DRAG: POSITION Y (Home Key -> F21)
; ---------------------------------------------------------
*F21:: {
    Global MacroReleased := false
    MouseGetPos(&origX, &origY)

    Click() ; Selects the clip under the cursor
    Sleep(50)

    Send("{Shift down}1{Shift up}")
    Sleep(150)

    MouseMove(PosY_X, PosY_Y, 0)
    Click("Down")
    Sleep(150)

    ; --- TAP DETECTED ---
    if (MacroReleased) {
        Click("Up")
        Sleep(50)
        SendText("540")
        Sleep(50)
        Send("{Enter}")
        Sleep(50)
        MouseMove(origX, origY, 0)
        Sleep(50)
        Click()
        return
    }

    ; --- HOLD DETECTED ---
    MouseMove(PosY_X + 10, PosY_Y, 2)
    while (!MacroReleased) {
        Sleep(10)
    }

    Click("Up")
    MouseMove(origX, origY, 0)
    Sleep(50)
    Click()
}

; ---------------------------------------------------------
; VALUE DRAG: ROTATION (Page Up -> F22)
; ---------------------------------------------------------
*F22:: {
    Global MacroReleased := false
    MouseGetPos(&origX, &origY)

    Click() ; Selects the clip under the cursor
    Sleep(50)

    Send("{Shift down}1{Shift up}")
    Sleep(150)

    MouseMove(Rot_X, Rot_Y, 0)
    Click("Down")
    Sleep(150)

    ; --- TAP DETECTED ---
    if (MacroReleased) {
        Click("Up")
        Sleep(50)
        SendText("0")
        Sleep(50)
        Send("{Enter}")
        Sleep(50)
        MouseMove(origX, origY, 0)
        Sleep(50)
        Click()
        return
    }

    ; --- HOLD DETECTED ---
    MouseMove(Rot_X + 10, Rot_Y, 2)
    while (!MacroReleased) {
        Sleep(10)
    }

    Click("Up")
    MouseMove(origX, origY, 0)
    Sleep(50)
    Click()
}

; ---------------------------------------------------------
; AUDIO GAIN (Ins / Del)
; ---------------------------------------------------------
; Insert Key mapped via LuaMacros to Ctrl+Alt+F13
^!F13:: {
    AddGain(6)
}

; Delete Key mapped via LuaMacros to Ctrl+Alt+F14
^!F14:: {
    AddGain(-6)
}

AddGain(amount) {
    Send("g")        ; Opens the Audio Gain dialog (ensure 'G' is mapped in Premiere)
    Sleep(50)
    SendText(amount) ; Types the amount (e.g., "6" or "-6")
    Sleep(50)
    Send("{Enter}")  ; Confirms
}
#HotIf