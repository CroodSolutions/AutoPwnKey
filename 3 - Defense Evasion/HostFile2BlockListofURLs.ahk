#Requires AutoHotkey v2.0

; Global variables
hostFile := A_WinDir "\System32\drivers\etc\hosts"
domains := ["example1.com", "example2.com", "example3.com"] ; Add more domains as needed
redirectIP := "127.0.0.1"

; Check if the hosts file exists, create it if it doesn't
if !FileExist(hostFile) {
    try {
        FileAppend("", hostFile)
    } catch as err {
        MsgBox("Unable to create hosts file: " . hostFile . "`nError: " . err.Message, "Error", 16)
        ExitApp
    }
}

; Declare file handle variable with a name that's not reserved
fileHandle := ""

; Open the hosts file in append mode
try {
    fileHandle := FileOpen(hostFile, "a")
    if !fileHandle {
        throw Error("Failed to open file.")
    }
} catch as err {
    MsgBox("Unable to open hosts file: " . hostFile . "`nError: " . err.Message, "Error", 16)
    ExitApp
}

; Write domain entries to the hosts file
try {
    for domain in domains {
        fileHandle.WriteLine(redirectIP . " " . domain)
        fileHandle.WriteLine(redirectIP . " www." . domain)
    }
} catch as err {
    MsgBox("Error writing to hosts file: " . err.Message, "Error", 16)
} finally {
    if fileHandle {
        fileHandle.Close()  ; Ensure the file is closed even if an error occurs
    }
}

; Show success message
MsgBox("Hosts file updated to redirect specified domains to 127.0.0.1", "Success", 64)
ExitApp