#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)

global socket := 0

Log(msg) {
    FileAppend "PortTest: " msg "`n", "*"
}

TestPort(ip, port, timeout := 5000) {
    Try {
        ; Constants
        FD_READ := 1
        FD_CLOSE := 32 
        FD_CONNECT := 20
        AF_INET := 2
        SOCK_STREAM := 1
        IPPROTO_TCP := 6
        SizeOfSocketAddress := 16
        SOCKET_ERROR := -1
        
        Log("Starting connection test to " ip ":" port)

        ; Initialize WSA
        Try {
            wsaData := Buffer(32, 0)
            result := DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData.Ptr)
            if (result != 0) {
                error := DllCall("Ws2_32\WSAGetLastError")
                Log("WSAStartup failed with error: " error)
                return error
            }
        } Catch as err {
            Log("WSAStartup critical error: " err.Message)
            return -1
        }
        
        Log("WSAStartup successful")

        ; Create socket
        Try {
            socket := DllCall("Ws2_32\socket", "Int", AF_INET, "Int", SOCK_STREAM, "Int", IPPROTO_TCP, "Ptr")
            if (socket = INVALID_SOCKET := -1) {
                error := DllCall("Ws2_32\WSAGetLastError")
                Log("Socket creation failed with error: " error)
                CleanUpConnection()
                return error
            }
        } Catch as err {
            Log("Socket creation critical error: " err.Message)
            CleanUpConnection()
            return -1
        }

        Log("Socket created successfully")

        ; Convert IP address
        Try {
            translatedIP := DllCall("Ws2_32\inet_addr", "AStr", ip, "UInt")
            if (translatedIP = 0xFFFFFFFF) {
                Log("Invalid IP address format")
                CleanUpConnection()
                return -1
            }
        } Catch as err {
            Log("IP translation critical error: " err.Message)
            CleanUpConnection()
            return -1
        }

        ; Create socket address structure
        Try {
            SocketAddress := Buffer(16, 0)  ; sizeof(sockaddr_in) = 16
            NumPut("UShort", AF_INET, SocketAddress, 0)  ; sin_family
            NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), SocketAddress, 2)  ; sin_port
            NumPut("UInt", translatedIP, SocketAddress, 4)  ; sin_addr
        } Catch as err {
            Log("Address structure creation error: " err.Message)
            CleanUpConnection()
            return -1
        }

        Log("Attempting connection...")

        ; Connect
        Try {
            result := DllCall("Ws2_32\connect", "Ptr", socket, "Ptr", SocketAddress.Ptr, "Int", 16)
            if (result = SOCKET_ERROR) {
                error := DllCall("Ws2_32\WSAGetLastError")
                Log("Connect failed with error: " error)
                CleanUpConnection()
                return error
            }
        } Catch as err {
            Log("Connect critical error: " err.Message)
            CleanUpConnection()
            return -1
        }

        Log("Connection successful!")
        CleanUpConnection()
        return 0

    } Catch as err {
        Log("Unexpected error: " err.Message)
        Try {
            CleanUpConnection()
        }
        return -1
    }
}

CleanUpConnection() {
    Try {
        if (socket != 0) {
            DllCall("Ws2_32\closesocket", "Ptr", socket)
            Log("Socket closed")
        }
        DllCall("Ws2_32\WSACleanup")
        Log("WSA Cleaned up")
    } Catch as err {
        Log("Cleanup error: " err.Message)
    }
}

; Main script
Log("Script starting...")

Try {
    test := TestPort("8.8.8.8", "53")
    if (test) {
        Log("Test failed with error code: " test)
    } else {
        Log("Connected successfully")
    }
} Catch as err {
    Log("Main script error: " err.Message)
}

Sleep(1000)
ExitApp