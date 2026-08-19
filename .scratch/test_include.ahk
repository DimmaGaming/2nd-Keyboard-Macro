#Requires AutoHotkey v2.0
Global test1 := "Yes"
a::Return

Global test2 := "No"
FileAppend(test1 "," (IsSet(test2) ? test2 : "Unset"), "test_out.txt")
ExitApp
