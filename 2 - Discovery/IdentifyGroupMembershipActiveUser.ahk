#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)  ; Work in the script's directory.

; This will output the group membership for the current active user.
 
; Delete any existing output.txt file.
if FileExist("output.txt")
    FileDelete("output.txt")
 
; Get the command interpreter and current username from the environment.
comspec := EnvGet("ComSpec")
username := EnvGet("USERNAME")
 
; Write a header with the current username to output.txt.
cmd := comspec . " /c echo Membership info for " . username . " > output.txt"
RunWait(cmd, "", "Hide")
Sleep(500)  ; Pause briefly to ensure the file is updated.
 
; Append the output of the net user command to output.txt.
cmd := comspec . " /c net user " . username . " /domain >> output.txt"
RunWait(cmd, "", "Hide")
Sleep(500)
 
; Notify the user that the operation is complete.
MsgBox("Membership information for " . username . " has been written to output.txt.")
ExitApp()
