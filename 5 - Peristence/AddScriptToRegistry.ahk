#Requires AutoHotkey v2.0

CheckAndSetStartup() {
    subKey := "Software\Microsoft\Windows\CurrentVersion\Run"
    valueName := "StartUp_1"
    scriptPath := A_ScriptFullPath
    exePath := A_AhkPath
    value := Format( '"{}" "{}"', exePath, scriptPath)
    RegWrite(value, "REG_SZ", "HKEY_CURRENT_USER\" subKey, valueName)
}

CheckAndSetStartup()
