; Define reg key and value for startup
RegKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
RegName := "notmaliciousatall"
ScriptPath := A_ScriptFullPath

; Check if the script is already there
RegRead, OutputVar, %RegKey%, %RegName%

if (OutputVar = ScriptPath) {
    ; If the script is already there it will run this code, so put whatever here
    MsgBox, 0x40, Startup Status, I'm In! Ribbit
} else {
    ; Add the script to the startup registry
    RegWrite, REG_SZ, %RegKey%, %RegName%, %ScriptPath%
}

ExitApp