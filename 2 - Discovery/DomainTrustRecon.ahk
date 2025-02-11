#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)  ; Ensure a consistent starting directory.

; Retrieve the domain name from the environment variable.
domain := EnvGet("USERDOMAIN")
if (domain == "")
{
    MsgBox("Could not retrieve the domain name from USERDOMAIN.", "Error", 16)
    ExitApp()
}

; Build the command string to query the domain controllers.
cmd := EnvGet("ComSpec") . " /c nltest /dclist:" . domain . " > output.txt"

; Run the command and wait for it to finish (the window is hidden).
RunWait(cmd, "", "Hide")

; Notify the user that the output has been written.
MsgBox("The list of domain controllers for " . Chr(34) . domain . Chr(34) . " has been written to output.txt.")
ExitApp()
