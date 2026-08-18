#Requires AutoHotkey v2.0

; ==========================================
; GLOBAL CAPSLOCK CONTROL (Centralized)
; ==========================================
SetCapsLockState("AlwaysOff")
*CapsLock::Return

; ==========================================
; MASTER RELOAD HOTKEY (NOTEPAD ONLY)
; ==========================================
#HotIf WinActive("ahk_exe notepad.exe")
^!r:: {
    Reload()
}
#HotIf 

; ==========================================
; INCLUDED SCRIPTS
; ==========================================
#Include "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\Clipboard Paste Into Timeline.ahk"
#Include "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Black Arrow Keys Application Switch & Slide Effects.ahk"
#Include "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\All Effects Apply Script.ahk"
#Include "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\All Premiere Functions Added.ahk"
#Include "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\All Nest Presets Premiere script.ahk"