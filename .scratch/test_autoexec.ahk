#Requires AutoHotkey v2.0
Global testVar := "Not Set"
a::Return
Global testVar := "Set!"
FileAppend(testVar "`n", "*")
