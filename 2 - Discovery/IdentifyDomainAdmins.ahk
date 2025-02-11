#Requires AutoHotkey v2.0

SetWorkingDir(A_ScriptDir)  ; Ensure we work in the script's directory.

; Note that you can replace Domain Admins with any other group you are curious about.
; Delete the existing output.txt file if it exists.

if FileExist("output.txt")

    FileDelete("output.txt")
 
; Retrieve the path to cmd.exe from the environment.

comspec := EnvGet("ComSpec")
 
; Write a header to output.txt.

cmd := comspec . " /c echo Domain Admins: > output.txt"

RunWait(cmd, "", "Hide")
 
; Append the output of the net group command for "Domain Admins" to output.txt.

; Note that the group name is enclosed in doubled quotes.

cmd := comspec . ' /c net group "Domain Admins" /domain >> output.txt'

RunWait(cmd, "", "Hide")
 
MsgBox("The Domain Admins group membership has been written to output.txt.")

ExitApp()

 
