#Requires AutoHotkey v2.0

Log(msg, logFile := "logfile.txt") {
    logMessage :=  msg "`n"
    
    try {
        FileAppend(logMessage, "*")
    } catch Error as err {
        FileAppend(logMessage, logFile)
    }
}

Decrypt(encryptedBuffer, password) {
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
    
    ; Create decryption key
    hKey := Buffer(A_PtrSize)
    if !(DllCall("Advapi32\CryptDeriveKey", "Ptr", NumGet(hProvider, 0, "Ptr"), "UInt", 0x6801, "Ptr", NumGet(hHash, 0, "Ptr"), "UInt", 1, "Ptr", hKey.Ptr))
        throw Error("Failed to create key", -1)
    
    ; Decrypt the data
    decryptedSize := encryptedBuffer.Size
    decrypted := Buffer(decryptedSize)
    decrypted.Size := decryptedSize
    decrypted := encryptedBuffer  ; Copy the encrypted data
    
    if !DllCall("Advapi32\CryptDecrypt", "Ptr", NumGet(hKey, 0, "Ptr"), "Ptr", 0, "Int", 1, "UInt", 0, "Ptr", decrypted.Ptr, "UInt*", &decryptedSize)
        throw Error("Decryption failed", -1)
    
    ; Clean up
    DllCall("Advapi32\CryptDestroyKey", "Ptr", NumGet(hKey, 0, "Ptr"))
    DllCall("Advapi32\CryptDestroyHash", "Ptr", NumGet(hHash, 0, "Ptr"))
    DllCall("Advapi32\CryptReleaseContext", "Ptr", NumGet(hProvider, 0, "Ptr"), "UInt", 0)
    
    ; Return the buffer directly instead of converting to string
    decrypted.Size := decryptedSize  ; Update the buffer size to the decrypted size
    return decrypted
}

DecryptDirectory(targetFolder, password) {
    Loop Files, targetFolder "\*.encrypted", "FR"
    {
        Log("Processing: " A_LoopFileName "`n")
        
        ; Read the encrypted file
        fileObj := FileOpen(A_LoopFileFullPath, "r-d")
        if !fileObj {
            Log("Failed to open file`n")
            continue
        }
        
        fileSize := fileObj.Length
        encryptedBuffer := Buffer(fileSize)
        fileObj.RawRead(encryptedBuffer)
        fileObj.Close()
        
        try {
            ; Remove .encrypted from the path
            newPath := SubStr(A_LoopFileFullPath, 1, -10)  ; Remove ".encrypted"
            
            ; Decrypt the data
            decryptedData := Decrypt(encryptedBuffer, password)
            
            ; Write the decrypted data
            fileObj := FileOpen(newPath, "w-d")  ; write in binary mode
            if fileObj {
                fileObj.RawWrite(decryptedData, decryptedData.Size)
                fileObj.Close()
                FileDelete(A_LoopFileFullPath)
                Log("Successfully decrypted to: " newPath "`n")
            }
        } catch Error as err {
            Log("Error: " err.Message "`n")
        }
    }
}

targetFolder := A_MyDocuments "\Crypttest"
password := "Test1"
DecryptDirectory(targetFolder, password)