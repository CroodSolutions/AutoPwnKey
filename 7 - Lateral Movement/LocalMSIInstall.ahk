#Requires AutoHotkey v2.0
#SingleInstance Force

InstallMSI(url, downloadPath, installDir) {
    ; Create installation directory if it doesn't exist
    if !DirExist(installDir)
        DirCreate(installDir)
    
    ; Download the installer
    Download(url, downloadPath)
    
    ; Run installer with user-level installation parameters
    installCmd := 'msiexec.exe /i "' downloadPath '" /qn'
        . ' ALLUSERS=2'
        . ' MSIINSTALLPERUSER=1'
        . ' INSTALLDIR="' installDir '"'
    
    result := RunWait(installCmd,, "Hide")
    
    ; Clean up
    FileDelete(downloadPath)
    
    return result
}

; Working example usage
puttyUrl := "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.82-installer.msi"
downloadPath := A_Temp "\putty-installer.msi"
installDir := A_AppData "\PuTTY"

result := InstallMSI(puttyUrl, downloadPath, installDir)
