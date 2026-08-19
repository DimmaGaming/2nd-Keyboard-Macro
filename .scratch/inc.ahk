Global FirstFileX := 560
^!x:: {
    try {
        MouseMove(FirstFileX, 250)
        FileAppend("FirstFileX is " FirstFileX, "D:\Dimma\Coding Workflow\AutoHotKey Scripts\.scratch\test_abs.txt")
    } catch {
        FileAppend("Error", "D:\Dimma\Coding Workflow\AutoHotKey Scripts\.scratch\test_abs.txt")
    }
    ExitApp
}
