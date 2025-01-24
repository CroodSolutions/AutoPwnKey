#Requires AutoHotkey v2.0
#SingleInstance Force

GetServiceName(port) {
    static services := Map(
        20, "ftp-data",
        21, "ftp",
        22, "ssh",
        23, "telnet",
        25, "smtp",
        53, "domain",
        80, "http",
        110, "pop3",
        111, "rpcbind",
        135, "msrpc",
        139, "netbios-ssn",
        143, "imap",
        443, "https",
        445, "microsoft-ds",
        993, "imaps",
        995, "pop3s",
        1723, "pptp",
        3306, "mysql",
        3389, "ms-wbt-server",
        5900, "vnc",
        8080, "http-proxy",
        9929, "nping-echo",
        31337, "Elite"
    )
    return services.Has(port) ? services[port] : "unknown"
}

Log(msg, logFile := "logfile.txt") {
    logMessage :=  msg "`n"
    
    try {
        FileAppend(logMessage, "*")
    } catch Error as err {
        FileAppend(logMessage, logFile)
    }
}

UpdateProgress(current, total) {
    percentage := Round((current / total) * 100)
    
    Log("`rScanning... " " " percentage "% complete")
}

ParsePortRange(portRange) {
    ports := []
    ranges := StrSplit(portRange, ",")
    
    for range in ranges {
        if InStr(range, "-") {
            parts := StrSplit(range, "-")
            if (parts.Length != 2)
                continue
                
            start := Integer(parts[1])
            end := Integer(parts[2])
            
            if (start > end || start < 1 || end > 65535)
                continue
                
            Loop (end - start + 1)
                ports.Push(start + A_Index - 1)
        } else {
            port := Integer(range)
            if (port >= 1 && port <= 65535)
                ports.Push(port)
        }
    }
    
    return ports
}

TestPort(ip, port) {
    ; Constants
    AF_INET := 2
    SOCK_STREAM := 1
    IPPROTO_TCP := 6
    SOCKET_ERROR := -1
    WSAECONNREFUSED := 10061
    WSAETIMEDOUT := 10060

    ; Initialize WSA
    wsaData := Buffer(408)
    if (DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData)) {
        Log("WSAStartup failed")
        return "error"
    }

    ; Create socket
    sock := DllCall("Ws2_32\socket", "Int", AF_INET, "Int", SOCK_STREAM, "Int", IPPROTO_TCP)
    if (sock = -1) {
        DllCall("Ws2_32\WSACleanup")
        Log("Socket creation failed")
        return "error"
    }

    ; Set timeout (3 seconds)
    timeout := Buffer(8, 0)
    NumPut("Int", 3000, timeout, 0)
    DllCall("Ws2_32\setsockopt", "Ptr", sock, "Int", 0xFFFF, "Int", 0x1005, "Ptr", timeout, "Int", 4)
    DllCall("Ws2_32\setsockopt", "Ptr", sock, "Int", 0xFFFF, "Int", 0x1006, "Ptr", timeout, "Int", 4)

    ; Create sockaddr structure
    sockaddr := Buffer(16, 0)
    NumPut("UShort", AF_INET, sockaddr, 0)
    NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), sockaddr, 2)
    NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", ip), sockaddr, 4)

    ; Try to connect
    result := DllCall("Ws2_32\connect", "Ptr", sock, "Ptr", sockaddr, "Int", 16)
    
    ; Get error code if connection failed
    error := 0
    if (result = SOCKET_ERROR) {
        error := DllCall("Ws2_32\WSAGetLastError")
    }

    ; Clean up
    DllCall("Ws2_32\closesocket", "Ptr", sock)
    DllCall("Ws2_32\WSACleanup")

    ; Return appropriate status
    if (result = 0)
        return "open"
    else if (error = WSAECONNREFUSED)
        return "closed"
    else if (error = WSAETIMEDOUT)
        return "filtered"
    else
        return "filtered"  ; Most other errors indicate filtering
}

; Main script
startTime := A_TickCount

; Initial output
Log("Starting AutoPwnKey Port Scanner at " FormatTime(, "yyyy-MM-dd HH:mm") " " )
Log("")

; Parse and scan ports
ports := ParsePortRange("20-25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080,9929,31337")
host := "45.33.32.156"
Log("Scan report for " host)
Log("")


openPorts := []
closedPorts := []
filteredPorts := []

totalPorts := ports.Length
scannedPorts := 0

; Scan all ports first
for port in ports {
    result := TestPort(host, port)
    scannedPorts++
    
    switch result {
        case "open":
            openPorts.Push(port)
        case "closed":
            closedPorts.Push(port)
        case "filtered":
            filteredPorts.Push(port)
    }
    
    UpdateProgress(scannedPorts, totalPorts)
    Sleep(100)
}
; Calculate stats
closedCount := closedPorts.Length
filteredCount := filteredPorts.Length
openCount := openPorts.Length

; Print final report
if (closedCount = totalPorts) {
    Log("All " totalPorts " scanned ports are closed")
} else {
    if (closedCount > 0) {
        Log("Not shown: " closedCount " closed tcp ports")
    }
    if (filteredCount > 0) {
        Log(filteredCount " filtered port" (filteredCount = 1 ? "" : "s"))
    }
    
    Log("")
    Log("PORT      STATE    SERVICE")
    
    ; Print open ports
    for port in openPorts {
        serviceName := GetServiceName(port)
        Log(Format("{:-8}/tcp {:-8} {}", port, "open", serviceName))
    }
    
    ; Print filtered ports
    for port in filteredPorts {
        serviceName := GetServiceName(port)
        Log(Format("{:-8}/tcp {:-8} {}", port, "filtered", serviceName))
    }
}

; Print timing information
elapsedTime := (A_TickCount - startTime) / 1000
Log("`nScan completed in " Format("{:.2f}", elapsedTime) " seconds")

ExitApp