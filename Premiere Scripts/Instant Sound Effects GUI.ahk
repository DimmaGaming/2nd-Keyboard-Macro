#Requires AutoHotkey v2.0
SetWinDelay(0)
CoordMode("Mouse", "Screen")
SendMode("Event")

global SFXFolder := "D:\Dimma\Editing\AHK Sound Effects Folder"
global SFXMousePosFile := A_Temp "\sfx_mouse_pos.txt"
global SFXDragTriggerFile := A_Temp "\sfx_drag_trigger.txt"

global WM_SHOWME := 0x0401
global WM_HIDEME := 0x0402

; Clean up old triggers on start
try FileDelete(SFXDragTriggerFile)

SetTimer(CheckForDragTrigger, 20) ; Faster timer check

CheckForDragTrigger() {
    if FileExist(SFXDragTriggerFile) {
        ; Read item coordinates from C#
        coords := FileRead(SFXDragTriggerFile)
        try FileDelete(SFXDragTriggerFile)
        
        lines := StrSplit(coords, "`n", "`r")
        if (lines.Length >= 2) {
            itemX := Integer(lines[1])
            itemY := Integer(lines[2])
            
            ; Read original mouse coords
            origCoords := ""
            try origCoords := FileRead(SFXMousePosFile)
            origLines := StrSplit(origCoords, "`n", "`r")
            if (origLines.Length >= 2) {
                origX := Integer(origLines[1])
                origY := Integer(origLines[2])
                
                ; AHK performs the drag and drop physically!
                
                ; 1. Move to the selected item in the C# window (instant)
                MouseMove(itemX, itemY, 0)
                Sleep(20)
                
                ; 2. Click down on the item
                Click("Down")
                Sleep(20) 
                
                ; 3. Drag slightly inside the window to trigger WPF's drag detection
                MouseMove(itemX + 10, itemY + 10, 2)
                Sleep(20)
                
                ; 4. Drag it back to the original Premiere cursor position
                MouseMove(origX, origY, 2)
                Sleep(30)
                
                ; 5. Release mouse to drop it onto the timeline
                Click("Up")
                
                ; Tell C# window to hide itself cleanly
                DetectHiddenWindows(True)
                if WinExist("Instant SFX Dragger")
                    PostMessage(WM_HIDEME, 0, 0, , "Instant SFX Dragger")
                
                ; Ensure Premiere is in focus!
                WinActivate("ahk_class Premiere Pro")
            }
        }
    }
}

; ============================================================
; PREMIERE PRO HOTKEYS
; ============================================================
#HotIf WinActive("ahk_class Premiere Pro")

^Space:: {
    MouseGetPos(&mx, &my)
    try FileDelete(SFXMousePosFile)
    FileAppend(mx "`n" my, SFXMousePosFile)

    DetectHiddenWindows(True)
    if WinExist("Instant SFX Dragger") {
        ; Ask C# to show itself natively instead of forcing it via OS
        PostMessage(WM_SHOWME, 0, 0, , "Instant SFX Dragger")
    } else {
        Run('`"D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\SFXDragger.exe`" `"' SFXFolder '`"')
    }
}

#HotIf