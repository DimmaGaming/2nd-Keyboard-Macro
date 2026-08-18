#Requires AutoHotkey v2.0

; ==========================================
; THE CORE WORKFLOW FUNCTION
; ==========================================
ApplyCapsEffect(effectName) {
    EffectResultX := 3300 
    EffectResultY := 350  
    EffCtrlMidX := -1900   
    EffCtrlMidY := 1300    
    ShortcutEffectsPanel := "+3"
    ShortcutEffectControls := "+2"
    ShortcutFindBox := "+f"
    UI_Wait := 180
    Drag_Speed := 2 

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
    Send("{Enter}") ; <--- COMMIT the empty box so Premiere doesn't restore the text
    Sleep(30)
    Send("{Esc}")   ; <--- DROP text focus cleanly
    Sleep(UI_Wait)
    
    Send(ShortcutEffectControls)
   ;Sleep(UI_Wait)
   ;MouseMove(EffCtrlMidX, EffCtrlMidY, 0)
}

#HotIf WinActive("ahk_exe Adobe Premiere Pro.exe") and GetKeyState("CapsLock", "P")

1::ApplyCapsEffect("broll image")
s::ApplyCapsEffect("soft shadow")
b::ApplyCapsEffect("Aesthetic BG Blur")
u::ApplyCapsEffect("green screen")
t::ApplyCapsEffect("test zoom")
z::ApplyCapsEffect("slow zoom in")
x::ApplyCapsEffect("slow zoom out")
l::ApplyCapsEffect("dimma's little shake")
g::ApplyCapsEffect("wonder glow")
c::ApplyCapsEffect("crop")
q::ApplyCapsEffect("motion tween")
w::ApplyCapsEffect("watermark mosaic")
3::ApplyCapsEffect("basic 3d pan")
h::ApplyCapsEffect("horizontal flip")
v::ApplyCapsEffect("vertical flip")
n::ApplyCapsEffect("black & white")

#HotIf