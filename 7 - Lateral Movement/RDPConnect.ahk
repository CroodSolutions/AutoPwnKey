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
hostname := "Hostname.domain"  ; or IP address
username := "Administrator"
password := "Password"
;domain := "DOMAIN"  ; Optional

result := ConnectRDP(hostname, username, password)
