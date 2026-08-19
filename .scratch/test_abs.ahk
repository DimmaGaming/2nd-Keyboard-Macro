#Requires AutoHotkey v2.0
MyFunc()
F24::Return
FirstFileX := 560
MyFunc() {
    Global FirstFileX
    try {
        MouseMove(FirstFileX, 250)
        FileAppend("Worked", "D:\Dimma\Coding Workflow\AutoHotKey Scripts\.scratch\test_abs.txt")
    } catch as e {
        FileAppend("Error: " e.Message, "D:\Dimma\Coding Workflow\AutoHotKey Scripts\.scratch\test_abs.txt")
    }
    ExitApp
}
