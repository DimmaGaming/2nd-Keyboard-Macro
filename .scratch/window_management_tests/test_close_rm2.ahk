#Requires AutoHotkey v2.0
DetectHiddenWindows True
if WinExist("ahk_class RainmeterMeterWindow") {
    WinClose("ahk_class RainmeterMeterWindow")
} else {
    MsgBox("Rainmeter window not found")
}
