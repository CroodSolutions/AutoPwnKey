#Requires AutoHotkey v2.0

; Requires Admin

UpdateHostsFile(url, ip := "127.0.0.1") {
    hostFile := A_WinDir "\System32\drivers\etc\hosts"
        
    try {
        FileAppend(ip " " url "`n", hostFile)
        FileAppend(ip " www." url "`n", hostFile)
        return true
    }
    catch as err {
        return false
    }
}

UpdateHostsFile("example.com", "192.168.1.1")