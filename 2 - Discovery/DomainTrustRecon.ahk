#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)  ; Use the script’s directory.

; Delete the existing output.txt file if it exists.
if FileExist("output.txt")
    FileDelete("output.txt")

; Get the path to the command interpreter (cmd.exe).
comspec := EnvGet("ComSpec")

; Write header for Trusted Domains.
cmd := comspec . " /c echo Trusted Domains: > output.txt"
RunWait(cmd, "", "Hide")

; Append the output of the /trusted_domains command.
cmd := comspec . " /c nltest /trusted_domains >> output.txt"
RunWait(cmd, "", "Hide")


MsgBox("The domain trust information has been written to output.txt.")
ExitApp()
