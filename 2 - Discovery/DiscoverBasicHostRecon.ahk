#Requires AutoHotkey v2.0

; Define the output file path
outputFilePath := A_ScriptDir "\output.txt"

; Delete the file if it already exists
if FileExist(outputFilePath)
    FileDelete(outputFilePath)

; Run the systeminfo command and capture the output
systemInfo := RunCommand("systeminfo")

; Run the arp -a command and capture the output
arpInfo := RunCommand("arp -a")

; Combine the outputs
results := "System Information:`r`n" systemInfo "`r`n`r`nARP Information:`r`n" arpInfo

; Write the results to the output file
FileAppend(results, outputFilePath)

; Function to run a command and capture the output
RunCommand(cmd) {
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(A_ComSpec " /c " cmd)
    return exec.StdOut.ReadAll()
}