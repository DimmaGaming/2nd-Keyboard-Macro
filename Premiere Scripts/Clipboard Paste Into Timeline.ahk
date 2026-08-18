#Requires AutoHotkey v2.0
SetTitleMatchMode(2) ; Allows WinWait to match partial window titles.

; ============================================================
; USER SETTINGS
; ============================================================

ClipboardFolder := "D:\Dimma\Editing\All Editing Images Folder"
FolderWindowTitle := "All Editing Images Folder"
PremiereExe := "ahk_exe Adobe Premiere Pro.exe" 

PythonExe := "python"
PythonScript := "D:\Dimma\Coding Workflow\AutoHotKey Scripts\Premiere Scripts\Clipboard Paste Into Timeline Python Script.py"

FirstFileX := 560
FirstFileY := 250

; --- SPEED SETTINGS (in milliseconds) ---
WaitAfterClick    := 100   ; Time for Windows to register the left-click.
WaitAfterNudge    := 100   ; Time to trigger the drag-and-drop state.
WaitAfterSwap     := 155  ; Time for Premiere to come to the foreground.
WaitBeforeDrop    := 100  ; Time for Premiere's UI to register the hover before letting go.

; ============================================================
; HOTKEY DEFINITION: ^+!F17
; ============================================================
^+!F17::
{
    ; --------------------------------------------------------
    ; STEP 1: Remember mouse position & Old File
    ; --------------------------------------------------------
    CoordMode("Mouse", "Screen")
    MouseGetPos(&OriginalX, &OriginalY)
    
    OldNewestFile := GetNewestFile(ClipboardFolder)

    ; --------------------------------------------------------
    ; STEP 2: Call Python to save the image
    ; --------------------------------------------------------
    RunWait(PythonExe ' "' PythonScript '" "' ClipboardFolder '"', , "Hide")

    ; --------------------------------------------------------
    ; STEP 3: Wait for file to hit the hard drive
    ; --------------------------------------------------------
    Loop 300 
    {
        CurrentNewest := GetNewestFile(ClipboardFolder)
        if (CurrentNewest != OldNewestFile && CurrentNewest != "") {
            break 
        }
        Sleep(10) 
    }
    
    ; Give the OS a tiny 50ms buffer to finalize the icon placement
    Sleep(50) 

    ; --------------------------------------------------------
    ; STEP 4: Handle Explorer (FAST Z-Order Swap)
    ; --------------------------------------------------------
    if WinExist(FolderWindowTitle " ahk_class CabinetWClass") 
    {
        ; If you accidentally minimized it manually, restore it
        if (WinGetMinMax(FolderWindowTitle " ahk_class CabinetWClass") = -1) {
            WinRestore(FolderWindowTitle " ahk_class CabinetWClass")
            Sleep(200) 
        }
        
        ; Bring to front. No animation delay, no F5 needed!
        WinActivate(FolderWindowTitle " ahk_class CabinetWClass")
        WinWaitActive(FolderWindowTitle " ahk_class CabinetWClass")
        
        ; Clear old ghost selections quickly
        Send("{Esc}")
        Sleep(30)
    } 
    else 
    {
        Run('explorer.exe "' ClipboardFolder '"')
        WinWait(FolderWindowTitle " ahk_class CabinetWClass")
        WinActivate(FolderWindowTitle " ahk_class CabinetWClass")
        WinWaitActive(FolderWindowTitle " ahk_class CabinetWClass")
        WinMaximize(FolderWindowTitle " ahk_class CabinetWClass") 
        Sleep(150)
    }

    ; --------------------------------------------------------
    ; STEP 5: Grab the new file
    ; --------------------------------------------------------
    CoordMode("Mouse", "Client")
    MouseMove(FirstFileX, FirstFileY, 0)
    
    Click("Down") 
    Sleep(WaitAfterClick) 
    
    MouseMove(FirstFileX + 10, FirstFileY + 10, 0)
    Sleep(WaitAfterNudge)
    
    ; --------------------------------------------------------
    ; STEP 6: EXPLICITLY ACTIVATE PREMIERE PRO
    ; --------------------------------------------------------
    if WinExist(PremiereExe) {
        WinActivate(PremiereExe)
    } else {
        Send("!{Esc}")
    }
    Sleep(WaitAfterSwap) 
    
    ; --------------------------------------------------------
    ; STEP 7: Drag back to Premiere
    ; --------------------------------------------------------
    CoordMode("Mouse", "Screen")
    
    MouseMove(OriginalX, OriginalY, 0)
    Sleep(WaitBeforeDrop) 
    
    Click("Up")

    ; --------------------------------------------------------
    ; STEP 8: Clean up (PUSH TO BOTTOM)
    ; --------------------------------------------------------
    ; This hides the folder behind Premiere but keeps its UI awake!
    WinMoveBottom(FolderWindowTitle " ahk_class CabinetWClass")
}

; ============================================================
; HELPER FUNCTION: Get the newest file in a folder
; ============================================================
GetNewestFile(Dir)
{
    NewestTime := 0
    NewestFileName := ""
    
    Loop Files, Dir "\*.*"
    {
        if (A_LoopFileTimeModified > NewestTime) {
            NewestTime := A_LoopFileTimeModified
            NewestFileName := A_LoopFileName
        }
    }
    return NewestFileName
}

; ============================================================
; MODULE: Quit App (Alt + Q)
; ============================================================
!q::
{
    Send("!{F4}")
}

; ============================================================
; MODULE: Brave Fast Copy (Triggered via LuaMacros)
; ============================================================

; This ensures the hotkey ONLY triggers when Brave is your active window
#HotIf WinActive("ahk_exe brave.exe")

; Listens for Ctrl (^) + Shift (+) + Alt (!) + F18
^+!F18:: 
{
    Click("Right")
    Sleep(100)
    Send("y")
}

#HotIf