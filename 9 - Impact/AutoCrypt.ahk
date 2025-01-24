#Requires AutoHotkey v2.0
#SingleInstance Force

Log(msg, logFile := "logfile.txt") {
    logMessage :=  msg "`n"
    
    try {
        FileAppend(logMessage, "*")
    } catch Error as err {
        FileAppend(logMessage, logFile)
    }
}

Encrypt(data, password) {
    ; Create a buffer from the input data (assuming it's binary)
    dataBuffer := Buffer(data.Size)
    dataBuffer.Size := data.Size
    dataBuffer := data  ; Copy the binary data
    
    ; Create crypto provider and hash
    hProvider := Buffer(A_PtrSize)
    if !(DllCall("Advapi32\CryptAcquireContext", "Ptr", hProvider.Ptr, "Ptr", 0, "Ptr", 0, "UInt", 1, "UInt", 0xF0000000))
        throw Error("Failed to acquire crypto context", -1)
    
    hHash := Buffer(A_PtrSize)
    if !(DllCall("Advapi32\CryptCreateHash", "Ptr", NumGet(hProvider, 0, "Ptr"), "UInt", 0x8003, "Ptr", 0, "UInt", 0, "Ptr", hHash.Ptr))
        throw Error("Failed to create hash", -1)
    
    ; Hash the password
    pwSize := StrPut(password, "UTF-8") - 1
    pwBuffer := Buffer(pwSize)
    StrPut(password, pwBuffer, "UTF-8")
    
    if !DllCall("Advapi32\CryptHashData", "Ptr", NumGet(hHash, 0, "Ptr"), "Ptr", pwBuffer.Ptr, "UInt", pwSize, "UInt", 0)
        throw Error("Failed to hash password", -1)
    
    ; Create encryption key
    hKey := Buffer(A_PtrSize)
    if !(DllCall("Advapi32\CryptDeriveKey", "Ptr", NumGet(hProvider, 0, "Ptr"), "UInt", 0x6801, "Ptr", NumGet(hHash, 0, "Ptr"), "UInt", 1, "Ptr", hKey.Ptr))
        throw Error("Failed to create key", -1)
    
    ; Calculate required buffer size for encrypted data
    encryptedSize := data.Size
    if !DllCall("Advapi32\CryptEncrypt", "Ptr", NumGet(hKey, 0, "Ptr"), "Ptr", 0, "Int", 1, "UInt", 0, "Ptr", 0, "UInt*", &encryptedSize, "UInt", data.Size)
        throw Error("Failed to calculate encryption size", -1)
    
    ; Create properly sized buffer and encrypt the data
    encrypted := Buffer(encryptedSize)
    encrypted.Size := encryptedSize
    encrypted := data  ; Copy original data
    finalSize := data.Size
    
    if !DllCall("Advapi32\CryptEncrypt", "Ptr", NumGet(hKey, 0, "Ptr"), "Ptr", 0, "Int", 1, "UInt", 0, "Ptr", encrypted.Ptr, "UInt*", &finalSize, "UInt", encrypted.Size)
        throw Error("Encryption failed", -1)
    
    ; Clean up
    DllCall("Advapi32\CryptDestroyKey", "Ptr", NumGet(hKey, 0, "Ptr"))
    DllCall("Advapi32\CryptDestroyHash", "Ptr", NumGet(hHash, 0, "Ptr"))
    DllCall("Advapi32\CryptReleaseContext", "Ptr", NumGet(hProvider, 0, "Ptr"), "UInt", 0)
    
    return encrypted
}

EncryptDirectory(targetFolder, password) {
    Loop Files, targetFolder "\*.*", "FR"
    {
        if (StrLower(SubStr(A_LoopFileName, -9)) = ".encrypted")
            continue
            
        Log("Processing: " A_LoopFileName "`n")
        
        ; Read the original file as binary
        fileObj := FileOpen(A_LoopFileFullPath, "r-d")  ; binary mode
        if !fileObj {
            Log("Failed to open file`n")
            continue
        }
        
        fileSize := fileObj.Length
        fileBuffer := Buffer(fileSize)
        fileObj.RawRead(fileBuffer)
        fileObj.Close()
        
        ; Encrypt the data
        encryptedData := Encrypt(fileBuffer, password)
        
        ; Keep original extension and append .encrypted
        newPath := A_LoopFileFullPath ".encrypted"
        
        ; Write encrypted data
        fileObj := FileOpen(newPath, "w-d")  ; write in binary mode
        if fileObj {
            fileObj.RawWrite(encryptedData, encryptedData.Size)
            fileObj.Close()
            FileDelete(A_LoopFileFullPath)
            Log("Successfully encrypted to: " newPath "`n")
        }
    }
}

targetFolder := A_MyDocuments "\Crypttest"
; passwordLocation := A_Desktop "\AutoCrypt_Password.txt"
password := "Test1"

EncryptDirectory(targetFolder, password)


