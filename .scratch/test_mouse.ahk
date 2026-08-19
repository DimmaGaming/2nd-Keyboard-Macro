#Requires AutoHotkey v2.0
Global FirstFileX
Global FirstFileY
Try {
    MouseMove(FirstFileX, FirstFileY)
    FileAppend("No error", A_ScriptDir "\test_mouse.txt")
} Catch as e {
    FileAppend("Error: " e.Message, A_ScriptDir "\test_mouse.txt")
}
ExitApp
