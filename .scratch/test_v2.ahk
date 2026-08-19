#Requires AutoHotkey v2.0
Global out := ""
out .= "Top of script`n"
a:: {
    MsgBox("a pressed")
}
out .= "Bottom of script`n"
FileAppend(out, "test_v2.txt")
ExitApp
