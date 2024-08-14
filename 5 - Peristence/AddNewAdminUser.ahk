; AutoHotKey Script to create and run a PowerShell script to create a new local account

; Define the path to the PowerShell script
PowerShellScriptPath := "C:\Scripts\CreateLocalAccount.ps1"
PowerShellOutputPath := "C:\Scripts\output.txt"

; content of the PowerShell script
PowerShellScriptContent =
(
# Params for the new account
$UserName = "NewUser"
$Password = "P@ssw0rd123!" | ConvertTo-SecureString -AsPlainText -Force
$FullName = "New Local User"

# Create the new account
New-LocalUser -Name $UserName -Password $Password -FullName $FullName -Description "Created by PowerShell script"

# Add the new user to the Admin group
Add-LocalGroupMember -Group "Administrators" -Member $UserName

# Check if user was created
if (Get-LocalUser -Name $UserName) {
    "User created successfully." | Out-File -FilePath C:\Scripts\output.txt
} else {
    "Failed to create user." | Out-File -FilePath C:\Scripts\output.txt
}
)

; Create the directory if it doesn't exist
IfNotExist, C:\Scripts
{
    FileCreateDir, C:\Scripts
}

; Write the PowerShell script content to the file
FileDelete, %PowerShellScriptPath%
FileAppend, %PowerShellScriptContent%, %PowerShellScriptPath%

; Make sure the output file doesn't exist before running the script
FileDelete, %PowerShellOutputPath%

PowerShellExe := "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

Command := PowerShellExe . " -NoProfile -ExecutionPolicy Bypass -File """ . PowerShellScriptPath . """"

; Run the PowerShell script
RunWait, %Command%, , Hide

; Read the output from the PowerShell script
FileRead, OutputVar, %PowerShellOutputPath%

If InStr(OutputVar, "User created successfully.")
{
    MsgBox, 64, Success, The new local account was created successfully.
}
else
{
    MsgBox, 16, Error, Failed to create the new local account.
}

return
