#Requires AutoHotkey v2.0

class NTDLLManipulator {
    snapshots := Map()
    addresses := Map()
    hNTDLL := 0
    isModified := false
    originalBytes := ""
    modifiedAddress := 0
    modifiedSize := 0
    
    __New() {
        ; Create GUI
        this.gui := Gui("", "NTDLL Memory Manipulator")
        this.gui.SetFont("s9", "Consolas")
        

        this.btnTakeSnapshot := this.gui.Add("Button", "x20 y20 w160 h30", "Take Initial Snapshot")
        this.btnModify := this.gui.Add("Button", "x200 y20 w160 h30", "Modify NTDLL")
        this.btnCheck := this.gui.Add("Button", "x380 y20 w160 h30", "Check for Changes")
        
        this.btnClear := this.gui.Add("Button", "x20 y60 w160 h30", "Clear Log")
        this.btnUnhookNTDLL := this.gui.Add("Button", "x200 y60 w160 h30", "Unhook NTDLL")
        this.btnExit := this.gui.Add("Button", "x380 y60 w160 h30", "Exit")

        this.logEdit := this.gui.Add("Edit", "x20 y100 w560 h380 +Multi +ReadOnly +VScroll")
        
        this.btnReadFile := this.gui.Add("Button", "x20 y500 w160 h30", "Test NtReadFile") ; TODO: There are no logs for this without being unhooked?
        this.btnWriteFile := this.gui.Add("Button", "x200 y500 w160 h30", "Test NtWriteFile")
        ;this.btnRegistry := this.gui.Add("Button", "x380 y500 w160 h30", "Test Registry") TODO: Fix this
        ;this.btnNetConn := this.gui.Add("Button", "x20 y540 w160 h30", "Test NetConnection")
    
        ; Bind button events
        this.btnTakeSnapshot.OnEvent("Click", ObjBindMethod(this, "TakeInitialSnapshot"))
        this.btnModify.OnEvent("Click", ObjBindMethod(this, "ModifyNTDLL"))
        this.btnCheck.OnEvent("Click", ObjBindMethod(this, "CheckForChanges"))
        this.btnUnhookNTDLL.OnEvent("Click", ObjBindMethod(this, "HandleUnhookNTDLL"))
        this.btnClear.OnEvent("Click", ObjBindMethod(this, "ClearLog"))
        this.btnExit.OnEvent("Click", (*) => ExitApp())
        this.btnReadFile.OnEvent("Click", ObjBindMethod(this, "TestNtReadFile"))
        this.btnWriteFile.OnEvent("Click", ObjBindMethod(this, "TestNtWriteFile"))
        ;this.btnRegistry.OnEvent("Click", ObjBindMethod(this, "TestRegistry"))
        ;this.btnNetConn.OnEvent("Click", ObjBindMethod(this, "TestNetConnection"))
        
        ; Show GUI
        this.gui.Show()
    }
    
    LogWrite(text) {
        this.logEdit.Value := this.logEdit.Value . text . "`n"
        PostMessage(0x115, 7, 0, this.logEdit)
    }
    
    ClearLog(*) {
        this.logEdit.Value := ""
    }

    ; Test functions

    TestNtReadFile(*) {
        this.LogWrite("`nTesting NtReadFile...")
        
        ; First create a test file with content
        testFilePath := A_Temp "\ntdll_test.txt"
        try {
            FileAppend("Test content for NtReadFile", testFilePath)
            this.LogWrite("Created test file at: " . testFilePath)
        } catch Error as e {
            this.LogWrite("Failed to create test file: " . e.Message)
            return
        }
        
        ; Get function addresses
        hNtdll := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        NtCreateFile := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtCreateFile", "Ptr")
        NtReadFile := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtReadFile", "Ptr")
        
        ; Create NT path
        ntPath := "\??\" . testFilePath
        
        ; Initialize UNICODE_STRING for filename
        unicodeString := Buffer(16, 0)
        strPtr := Buffer(StrPut(ntPath, "UTF-16") * 2)
        StrPut(ntPath, strPtr, "UTF-16")
        NumPut("UShort", (StrPut(ntPath, "UTF-16") - 1) * 2, unicodeString, 0)  ; Length
        NumPut("UShort", (StrPut(ntPath, "UTF-16") - 1) * 2, unicodeString, 2)  ; MaximumLength
        NumPut("Ptr", strPtr.Ptr, unicodeString, 8)  ; Buffer
        
        ; Initialize OBJECT_ATTRIBUTES
        objAttributes := Buffer(48, 0)
        NumPut("UInt", objAttributes.Size, objAttributes, 0)  ; Length
        NumPut("Ptr", 0, objAttributes, A_PtrSize)           ; RootDirectory
        NumPut("Ptr", unicodeString.Ptr, objAttributes, 2*A_PtrSize)  ; ObjectName
        NumPut("UInt", 0x40, objAttributes, 3*A_PtrSize)     ; Attributes (OBJ_CASE_INSENSITIVE)
        
        ; Initialize IO_STATUS_BLOCK
        ioStatusBlock := Buffer(16, 0)
        
        ; Open the file
        hFile := 0
        status := DllCall(NtCreateFile,
            "Ptr*", &hFile,                ; FileHandle
            "UInt", 0x80100080,           ; DesiredAccess (FILE_READ_DATA | SYNCHRONIZE | FILE_READ_ATTRIBUTES)
            "Ptr", objAttributes,          ; ObjectAttributes
            "Ptr", ioStatusBlock,          ; IoStatusBlock
            "Int64", 0,                    ; AllocationSize
            "UInt", 0x80,                  ; FileAttributes (FILE_ATTRIBUTE_NORMAL)
            "UInt", 1,                     ; ShareAccess (FILE_SHARE_READ)
            "UInt", 3,                     ; CreateDisposition (OPEN_EXISTING)
            "UInt", 0x20,                  ; CreateOptions (FILE_SYNCHRONOUS_IO_NONALERT)
            "Ptr", 0,                      ; EaBuffer
            "UInt", 0)                     ; EaLength
        
        this.LogWrite("NtCreateFile status: 0x" . Format("{:X}", status))
        
        if (status = 0) {
            ; Prepare read buffer
            readBuffer := Buffer(1024, 0)
            bytesRead := 0
            
            ; Read from file
            status := DllCall(NtReadFile,
                "Ptr", hFile,              ; FileHandle
                "Ptr", 0,                  ; Event
                "Ptr", 0,                  ; ApcRoutine
                "Ptr", 0,                  ; ApcContext
                "Ptr", ioStatusBlock,      ; IoStatusBlock
                "Ptr", readBuffer,         ; Buffer
                "UInt", readBuffer.Size,   ; Length
                "Int64*", 0,              ; ByteOffset
                "Ptr", 0)                  ; Key
            
            if (status = 0) {
                ; Get the actual bytes read from IoStatusBlock
                bytesRead := NumGet(ioStatusBlock, 8, "UInt")
                fileContent := StrGet(readBuffer, bytesRead, "UTF-8")
                this.LogWrite("Successfully read " . bytesRead . " bytes")
                this.LogWrite("Content: " . fileContent)
            } else {
                this.LogWrite("NtReadFile failed with status: 0x" . Format("{:X}", status))
            }
            
            ; Close handle
            DllCall("CloseHandle", "Ptr", hFile)
        }
        
        ; Clean up test file
        try {
            FileDelete(testFilePath)
            this.LogWrite("Cleaned up test file")
        }
    }
    
    
    TestNtWriteFile(*) {
        this.LogWrite("`nTesting NtWriteFile...")
    
        if (!A_IsAdmin) {
            this.LogWrite("Warning: Running without admin privileges")
        }
        
        ; Get function addresses
        hNtdll := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        NtCreateFile := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtCreateFile", "Ptr")
        NtWriteFile := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtWriteFile", "Ptr")
        
        ; Setup test file path
        testFilePath := A_Temp "\ntdll_write_test.txt"
        ntPath := "\??\"  testFilePath
        
        ; Log the exact bytes
        this.LogWrite("Path length: " . StrLen(ntPath))
        this.LogWrite("Using NT path: " . ntPath)
        
        pathBuf := Buffer(StrPut(ntPath, "UTF-16"))
        StrPut(ntPath, pathBuf, "UTF-16")
        
        ; Log the first few bytes
        bytesStr := ""
        Loop 16 {
            bytesStr .= Format("{:02X} ", NumGet(pathBuf, A_Index-1, "UChar"))
        }
        this.LogWrite("First 16 bytes of path buffer: " . bytesStr)
        
        ; Initialize UNICODE_STRING properly
        unicodeString := Buffer(16, 0)
        NumPut("UShort", (StrLen(ntPath) * 2), unicodeString, 0)      ; Length in bytes
        NumPut("UShort", pathBuf.Size, unicodeString, 2)              ; MaximumLength in bytes
        NumPut("Ptr", pathBuf.Ptr, unicodeString, 8)                  ; Buffer pointer
        
        ; Log the UNICODE_STRING structure values
        this.LogWrite("UNICODE_STRING Length: " . NumGet(unicodeString, 0, "UShort"))
        this.LogWrite("UNICODE_STRING MaxLength: " . NumGet(unicodeString, 2, "UShort"))
        
        ; Initialize IO_STATUS_BLOCK
        ioStatusBlock := Buffer(16, 0)
        
        ; Initialize OBJECT_ATTRIBUTES
        objAttributes := Buffer(48, 0)
        NumPut("UInt", 48, objAttributes, 0)                          ; Length
        NumPut("Ptr", 0, objAttributes, A_PtrSize)                    ; RootDirectory
        NumPut("Ptr", unicodeString.Ptr, objAttributes, 2*A_PtrSize)  ; ObjectName
        NumPut("UInt", 0x40, objAttributes, 3*A_PtrSize)             ; Attributes
        
        ; Create file
        hFile := 0
        status := DllCall(NtCreateFile,
            "Ptr*", &hFile,
            "UInt", 0x40100080,      ; GENERIC_WRITE | SYNCHRONIZE | FILE_WRITE_ATTRIBUTES
            "Ptr", objAttributes,
            "Ptr", ioStatusBlock,
            "Int64*", 0,
            "UInt", 0x80,            ; FILE_ATTRIBUTE_NORMAL
            "UInt", 0x07,            ; FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE
            "UInt", 0x00000002,      ; FILE_CREATE
            "UInt", 0x20,            ; FILE_SYNCHRONOUS_IO_NONALERT
            "Ptr", 0,
            "UInt", 0)
        
        this.LogWrite("NtCreateFile status: 0x" . Format("{:X}", status))
        
        if (status = 0) {
            ; Prepare write buffer with test content
            testContent := "Test content written via NtWriteFile"
            writeBuffer := Buffer(StrPut(testContent, "UTF-8"))
            StrPut(testContent, writeBuffer, "UTF-8")
            
            ; Write to file
            status := DllCall(NtWriteFile,
                "Ptr", hFile,              ; FileHandle
                "Ptr", 0,                  ; Event
                "Ptr", 0,                  ; ApcRoutine
                "Ptr", 0,                  ; ApcContext
                "Ptr", ioStatusBlock,      ; IoStatusBlock
                "Ptr", writeBuffer,        ; Buffer
                "UInt", writeBuffer.Size - 1, ; Length (minus null terminator)
                "Ptr", 0,                  ; ByteOffset
                "Ptr", 0)                  ; Key
            
            if (status = 0) {
                bytesWritten := NumGet(ioStatusBlock, 8, "UInt")
                this.LogWrite("Successfully wrote " . bytesWritten . " bytes")
                
                ; Verify file contents
                try {
                    fileContent := FileRead(testFilePath)
                    this.LogWrite("Verified file content: " . fileContent)
                } catch Error as e {
                    this.LogWrite("Failed to verify file content: " . e.Message)
                }
            } else {
                this.LogWrite("NtWriteFile failed with status: 0x" . Format("{:X}", status))
            }
            
            ; Close handle
            DllCall("CloseHandle", "Ptr", hFile)
        }
        
        ; Verify file was created and clean up
        if FileExist(testFilePath) {
            this.LogWrite("Verified file exists at: " . testFilePath)
            try {
                FileDelete(testFilePath)
                this.LogWrite("Cleaned up test file")
            } catch Error as e {
                this.LogWrite("Failed to cleanup test file: " . e.Message)
            }
        } else {
            this.LogWrite("File was not created")
        }
    }
    
    TestRegistry(*) {
        this.LogWrite("`nTesting Registry operations...")
        
        ; Get function addresses
        hNtdll := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        if (!hNtdll) {
            this.LogWrite("Failed to get ntdll.dll handle")
            return
        }
        
        NtCreateKey := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtCreateKey", "Ptr")
        if (!NtCreateKey) {
            this.LogWrite("Failed to get NtCreateKey address")
            return
        }
        
        ; Initialize UNICODE_STRING for key path
        keyPath := "\REGISTRY\USER\CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
        strLen := StrPut(keyPath, "UTF-16")
        strPtr := Buffer((strLen) * 2)
        StrPut(keyPath, strPtr, "UTF-16")
        
        unicodeString := Buffer(16, 0)
        NumPut("UShort", (strLen - 1) * 2, unicodeString, 0)  ; Length in bytes
        NumPut("UShort", strLen * 2, unicodeString, 2)        ; MaximumLength in bytes
        NumPut("Ptr", strPtr.Ptr, unicodeString, 8)
        
        ; Initialize OBJECT_ATTRIBUTES
        objAttributes := Buffer(48, 0)
        NumPut("UInt", objAttributes.Size, objAttributes, 0)
        NumPut("Ptr", 0, objAttributes, A_PtrSize)
        NumPut("Ptr", unicodeString.Ptr, objAttributes, 2*A_PtrSize)
        NumPut("UInt", 64, objAttributes, 3*A_PtrSize)  ; OBJ_CASE_INSENSITIVE
        
        this.LogWrite("Key Path: " . keyPath)
        this.LogWrite("String Length: " . strLen)
        this.LogWrite("UNICODE_STRING size: " . unicodeString.Size)
        this.LogWrite("Object Attributes size: " . objAttributes.Size)
        
        hKey := 0
        disposition := 0
        status := DllCall(NtCreateKey,
            "Ptr*", &hKey,
            "UInt", 0xF003F,  ; KEY_ALL_ACCESS
            "Ptr", objAttributes,
            "UInt", 0,
            "Ptr", 0,
            "UInt", 0,
            "UInt*", &disposition)
        
        this.LogWrite("NtCreateKey status: 0x" . Format("{:X}", status))
        
        if (status = 0) {
            this.LogWrite("Registry key " . (disposition ? "created" : "opened") . " successfully")
            DllCall("RegCloseKey", "Ptr", hKey)
        } else {
            this.LogWrite("Failed to create/open registry key. Error code: 0x" . Format("{:X}", status))
        }
    }
    
    TestNetConnection(*) {
        this.LogWrite("`nTesting Network Connection...")
        
        hNtdll := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        NtCreateFile := DllCall("GetProcAddress", "Ptr", hNtdll, "AStr", "NtCreateFile", "Ptr")
        
        pipeName := "\??\pipe\ntdll_test_pipe"
        
        ; Initialize UNICODE_STRING
        unicodeString := Buffer(16, 0)
        strPtr := Buffer(StrPut(pipeName, "UTF-16") * 2)
        StrPut(pipeName, strPtr, "UTF-16")
        NumPut("UShort", (StrPut(pipeName, "UTF-16") - 1) * 2, unicodeString, 0)
        NumPut("UShort", (StrPut(pipeName, "UTF-16") - 1) * 2, unicodeString, 2)
        NumPut("Ptr", strPtr.Ptr, unicodeString, 8)
        
        ; Initialize OBJECT_ATTRIBUTES with proper attributes
        objAttributes := Buffer(48, 0)
        NumPut("UInt", objAttributes.Size, objAttributes, 0)
        NumPut("Ptr", 0, objAttributes, A_PtrSize)
        NumPut("Ptr", unicodeString.Ptr, objAttributes, 2*A_PtrSize)
        NumPut("UInt", 64, objAttributes, 3*A_PtrSize)  ; OBJ_CASE_INSENSITIVE
        
        ; Initialize IO_STATUS_BLOCK
        ioStatusBlock := Buffer(16, 0)
        
        hPipe := 0
        status := DllCall(NtCreateFile,
            "Ptr*", &hPipe,
            "UInt", 0x120116,  ; GENERIC_READ | GENERIC_WRITE | SYNCHRONIZE
            "Ptr", objAttributes,
            "Ptr", ioStatusBlock,
            "Int64", 0,
            "UInt", 0x80,
            "UInt", 3,
            "UInt", 1,
            "UInt", 0x60,
            "Ptr", 0,
            "UInt", 0)
        
        this.LogWrite("NtCreateFile (pipe) status: 0x" . Format("{:X}", status))
        
        if (status = 0) {
            this.LogWrite("Successfully created named pipe")
            DllCall("CloseHandle", "Ptr", hPipe)
        }
    }
    
    ; Core memory functions
    DumpMemorySection(hProcess, baseAddr, size) {
        if (baseAddr = 0) {
            this.LogWrite("Error: Invalid base address")
            return 0
        }
        
        buff1 := Buffer(size, 0)
        oldProtect := 0
        
        this.LogWrite("Attempting to read memory at: 0x" . Format("{:X}", baseAddr))
        
        ; Change protection
        if !DllCall("VirtualProtect", "Ptr", baseAddr, "UInt", size, "UInt", 0x40, "UInt*", &oldProtect) {
            this.LogWrite("Error: Failed to modify memory protection")
            return 0
        }
        
        bytesRead := 0
        result := DllCall("ReadProcessMemory", 
            "Ptr", hProcess,
            "Ptr", baseAddr,
            "Ptr", buff1.Ptr,
            "UInt", size,
            "UInt*", &bytesRead)
        
        ; Restore protection
        DllCall("VirtualProtect", "Ptr", baseAddr, "UInt", size, "UInt", oldProtect, "UInt*", &oldProtect)
        
        if (!result || bytesRead = 0) {
            this.LogWrite("Error: Failed to read memory section")
            return 0
        }
        
        this.LogWrite("Successfully read " . bytesRead . " bytes")
        return buff1
    }

    TakeInitialSnapshot(*) {
        this.LogWrite("`nStarting initial snapshot...")
        
        ; Get NTDLL handle
        hNTDLL := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        if (!hNTDLL) {
            this.LogWrite("Error: Failed to get NTDLL handle")
            return false
        }
        this.LogWrite("NTDLL Base Address: 0x" . Format("{:X}", hNTDLL))
        
        ; Get current process handle
        hProcess := DllCall("GetCurrentProcess", "Ptr")
        
        ; Functions to monitor
        functions := ["NtCreateFile", "NtReadFile", "NtWriteFile", "NtClose"]
        monitorSize := 0x200
        
        ; Take snapshots
        loop functions.Length {
            i := A_Index
            funcName := functions[i]
            this.LogWrite("`nProcessing " . funcName . "...")
            
            ; Get function address
            funcAddr := DllCall("GetProcAddress", "Ptr", hNTDLL, "AStr", funcName, "Ptr")
            if (!funcAddr) {
                this.LogWrite("Failed to get address for " . funcName)
                continue
            }
            
            this.LogWrite("Taking initial snapshot of " . funcName . " at: 0x" . Format("{:X}", funcAddr))
            this.snapshots[i] := this.DumpMemorySection(hProcess, funcAddr, monitorSize)
            this.addresses[i] := funcAddr
            
            if (!this.snapshots[i]) {
                this.LogWrite("Failed to take initial snapshot of " . funcName)
                continue
            }
        }
        
        this.LogWrite("`nInitial snapshots completed.")
        return true
    }

    ModifyNTDLL(*) {
        this.LogWrite("`nStarting NTDLL modification...")
        
        ; clean up any existing handles
        this._CleanupHandles()
        
        ; Get NTDLL handle
        this.hNTDLL := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        if (!this.hNTDLL) {
            this.LogWrite("Failed to get NTDLL handle")
            return false
        }
        
        ; Get NtCreateFile address
        NtCreateFile := DllCall("GetProcAddress", "Ptr", this.hNTDLL, "AStr", "NtCreateFile", "Ptr")
        if (!NtCreateFile) {
            this.LogWrite("Failed to get NtCreateFile address")
            return false
        }
        
        ; Memory barrier
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
        Sleep(100)
        
        ; Change protection
        oldProtect := 0
        if !DllCall("VirtualProtect", 
            "Ptr", NtCreateFile,
            "UInt", 16,
            "UInt", 0x40,  ; PAGE_EXECUTE_READWRITE
            "UInt*", &oldProtect) {
            this.LogWrite("VirtualProtect failed: " . A_LastError)
            return false
        }
        
        ; Save original bytes
        this.originalBytes := Buffer(16, 0)
        bytesRead := 0
        DllCall("ReadProcessMemory",
            "Ptr", DllCall("GetCurrentProcess", "Ptr"),
            "Ptr", NtCreateFile,
            "Ptr", this.originalBytes.Ptr,
            "UInt", 16,
            "UInt*", &bytesRead)
        
        ; Create test pattern (NOPs)
        testPattern := Buffer(16, 0x90)
        
        ; Write modification
        bytesWritten := 0
        result := DllCall("WriteProcessMemory",
            "Ptr", DllCall("GetCurrentProcess", "Ptr"),
            "Ptr", NtCreateFile,
            "Ptr", testPattern.Ptr,
            "UInt", 16,
            "UInt*", &bytesWritten)
        
        ; Set modified state
        this.isModified := true
        this.modifiedAddress := NtCreateFile
        this.modifiedSize := 16
        
        ; Memory barrier
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
        
        ; Restore protection
        DllCall("VirtualProtect",
            "Ptr", NtCreateFile,
            "UInt", 16,
            "UInt", oldProtect,
            "UInt*", &oldProtect)
        
        Sleep(1000)  ; Stability delay
        
        if (!result) {
            this.LogWrite("WriteProcessMemory failed: " . A_LastError)
            return false
        }
        
        this.LogWrite("Successfully modified NTDLL")
        return true
    }

    CheckForChanges(*) {
        if (!this.snapshots.Has(1)) {
            this.LogWrite("Error: No initial snapshots available. Please take snapshots first.")
            return false
        }
        
        hProcess := DllCall("GetCurrentProcess", "Ptr")
        functions := ["NtCreateFile", "NtReadFile", "NtWriteFile", "NtClose"]
        monitorSize := 0x1000  
        changesFound := false
        
        loop functions.Length {
            i := A_Index
            if (!this.snapshots.Has(i)) {
                this.LogWrite("Skipping " . functions[i] . " - No initial snapshot available")
                continue
            }
            
            ; Get current function address
            funcAddr := DllCall("GetProcAddress", 
                "Ptr", DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr"),
                "AStr", functions[i],
                "Ptr")
            
            newDump := this.DumpMemorySection(hProcess, funcAddr, monitorSize)
            if (!newDump) {
                this.LogWrite("Failed to take second snapshot of " . functions[i])
                continue
            }
            
            differences := 0
            modifications := ""
            
            ; Analyze first 32 bytes
            this.LogWrite("First 32 bytes of " . functions[i] . ":")
            hexDump := ""
            loop 32 {
                byte1 := NumGet(this.snapshots[i], A_Index-1, "UChar")
                byte2 := NumGet(newDump, A_Index-1, "UChar")
                hexDump .= Format("{:02X} ", byte2)
                
                if (byte1 != byte2) {
                    differences += 1
                    modifications .= Format("  Offset 0x{:02X}: {:02X} -> {:02X}`n", 
                        A_Index-1, byte1, byte2)
                    changesFound := true
                }
            }
            this.LogWrite(hexDump)
            
            if (differences > 0) {
                this.LogWrite("`n" . functions[i] . " was modified!")
                this.LogWrite("Found " . differences . " changes:")
                this.LogWrite(modifications)
            } else {
                this.LogWrite(functions[i] . " was not modified.")
            }
        }
        
        return true
    }

    SafeInitialize(*) {
        timer := A_TickCount
        success := false
        
        while (A_TickCount - timer < 5000) {  ; 5 second timeout
            if (this.Initialize()) {
                success := true
                break
            }
            Sleep(100)
        }
        
        if (!success) {
            this.LogWrite("Initialize timed out after 5 seconds")
        }
        return success
    }

    Initialize() {
        this.LogWrite("`nStarting NTDLL unhooking process with crash debugging...")
        
        ; Handle modified state
        if (this.isModified) {
            this.LogWrite("Warning: NTDLL is in modified state. Ensuring cleanup...")
            this._CleanupHandles()
            Sleep(1000)
        }
        
        ; Get memory info
        memInfo := Buffer(8, 0)  ; For WorkingSetSize
        DllCall("K32GetProcessMemoryInfo", 
            "Ptr", DllCall("GetCurrentProcess", "Ptr"), 
            "Ptr", memInfo.Ptr, 
            "UInt", memInfo.Size)
        this.LogWrite("Initial Working Set Size: " . NumGet(memInfo, 0, "Ptr"))
        
        ; Get NTDLL base
        ntdllBase := DllCall("GetModuleHandle", "Str", "ntdll.dll", "Ptr")
        if (!ntdllBase) {
            this.LogWrite("Failed to get NTDLL base address: " . A_LastError)
            return false
        }
        this.LogWrite("NTDLL Base Address: 0x" . Format("{:X}", ntdllBase))
        
        ; Memory barrier
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
        Sleep(100)
        
        ; Query NTDLL memory region
        mbi := Buffer(48, 0)  ; MEMORY_BASIC_INFORMATION
        querySuccess := false
        loop 3 {
            if (DllCall("VirtualQueryEx",
                "Ptr", DllCall("GetCurrentProcess", "Ptr"),
                "Ptr", ntdllBase,
                "Ptr", mbi.Ptr,
                "UInt", mbi.Size)) {
                querySuccess := true
                break
            }
            Sleep(100)
        }
        
        if (!querySuccess) {
            return false
        }
        
        this.LogWrite("NTDLL Memory Region Info:")
        this.LogWrite("  Protection: 0x" . Format("{:X}", NumGet(mbi, 20, "UInt")))
        this.LogWrite("  State: 0x" . Format("{:X}", NumGet(mbi, 16, "UInt")))
        this.LogWrite("  Type: 0x" . Format("{:X}", NumGet(mbi, 24, "UInt")))
        
        ; Open NTDLL file
        ntdllPath := A_WinDir . "\System32\ntdll.dll"
        try {
            this.LogWrite("Attempting to open file: " . ntdllPath)
            
            hFile := DllCall("CreateFileW",
                "Str", ntdllPath,
                "UInt", 0x80000000,  ; GENERIC_READ
                "UInt", 3,           ; FILE_SHARE_READ | FILE_SHARE_WRITE
                "Ptr", 0,
                "UInt", 3,           ; OPEN_EXISTING
                "UInt", 0x80,        ; FILE_ATTRIBUTE_NORMAL
                "Ptr", 0,
                "Ptr")
    
            if (hFile = -1 || !hFile) {
                lastError := A_LastError
                this.LogWrite("CreateFileW failed - Error Code: 0x" . Format("{:X}", lastError))
                this.LogWrite("Windows Error Message: " . this._GetWindowsErrorMessage(lastError))
                return false
            }
        } catch as err {
            this.LogWrite("Exception details:")
            this.LogWrite("  - Type: " . Type(err))
            this.LogWrite("  - Message: " . err.Message)
            this.LogWrite("  - Line: " . err.Line)
            this.LogWrite("  - What: " . err.What)
            this.LogWrite("  - Stack: " . err.Stack)
            
            if (A_LastError) {
                this.LogWrite("  - Last Windows Error: 0x" . Format("{:X}", A_LastError))
                this.LogWrite("  - Error Message: " . this._GetWindowsErrorMessage(A_LastError))
            }
            return false
        }
        this.LogWrite("Successfully opened NTDLL file from: " . ntdllPath)
        
        ; Create file mapping
        hMapping := DllCall("CreateFileMapping",
            "Ptr", hFile,
            "Ptr", 0,
            "UInt", 0x02,        ; PAGE_READONLY
            "UInt", 0,
            "UInt", 0,
            "Ptr", 0,
            "Ptr")
        
        if (!hMapping) {
            DllCall("CloseHandle", "Ptr", hFile)
            this.LogWrite("Failed to create file mapping")
            return false
        }
        this.LogWrite("Successfully created file mapping")
        
        ; Map view of file
        mappedView := DllCall("MapViewOfFile",
            "Ptr", hMapping,
            "UInt", 0x4,         ; FILE_MAP_READ
            "UInt", 0,
            "UInt", 0,
            "UInt", 0,
            "Ptr")
        
        if (!mappedView) {
            DllCall("CloseHandle", "Ptr", hMapping)
            DllCall("CloseHandle", "Ptr", hFile)
            this.LogWrite("Failed to map view of file")
            return false
        }
        this.LogWrite("Successfully mapped view of file")
        
        ; Process headers and sections
        try {
            this._ProcessPEHeaders(ntdllBase, mappedView)
        } catch as err {
            this.LogWrite("Error processing PE headers: " . err.Message)
        }
        
        ; Cleanup
        DllCall("UnmapViewOfFile", "Ptr", mappedView)
        DllCall("CloseHandle", "Ptr", hMapping)
        DllCall("CloseHandle", "Ptr", hFile)
        
        ; Final memory barrier
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
        
        ; Check final state
        DllCall("K32GetProcessMemoryInfo",
            "Ptr", DllCall("GetCurrentProcess", "Ptr"),
            "Ptr", memInfo.Ptr,
            "UInt", memInfo.Size)
        this.LogWrite("Final Working Set Size: " . NumGet(memInfo, 0, "Ptr"))
        
        this.isModified := false
        this.LogWrite("Cleanup completed - NTDLL unhooking process finished`n")
        return true
    }

    _ProcessPEHeaders(baseAddr, mappedView) {
        FileAppend("Starting PE header processing`n", "ntdll_debug.log")
        
        try {
            ; Read DOS header
            e_lfanew := NumGet(baseAddr + 0x3C, "UInt")
            FileAppend("e_lfanew: 0x" . Format("{:X}", e_lfanew) . "`n", "ntdll_debug.log")
            
            ; Get number of sections
            numberOfSections := NumGet(baseAddr + e_lfanew + 0x6, "UShort")
            FileAppend("Number of sections: " . numberOfSections . "`n", "ntdll_debug.log")
            
            ; Get size of optional header
            sizeOfOptionalHeader := NumGet(baseAddr + e_lfanew + 0x14, "UShort")
            FileAppend("Size of optional header: 0x" . Format("{:X}", sizeOfOptionalHeader) . "`n", "ntdll_debug.log")
            
            ; Calculate section headers offset
            sectionHeadersOffset := e_lfanew + 0x18 + sizeOfOptionalHeader
            FileAppend("Section headers offset: 0x" . Format("{:X}", sectionHeadersOffset) . "`n", "ntdll_debug.log")
            
            FileAppend("Base Address: 0x" . Format("{:X}", baseAddr) . "`n", "ntdll_debug.log")
            FileAppend("Mapped View: 0x" . Format("{:X}", mappedView) . "`n", "ntdll_debug.log")
            
            ; Process each section
            loop numberOfSections {
                try {
                    sectionHeader := baseAddr + sectionHeadersOffset + ((A_Index - 1) * 0x28)
                    sectionName := this._ReadSectionName(sectionHeader)
                    
                    ; both virtual and raw data information
                    virtualAddress := NumGet(sectionHeader + 0x0C, "UInt")
                    virtualSize := NumGet(sectionHeader + 0x08, "UInt")
                    rawAddress := NumGet(sectionHeader + 0x14, "UInt") 
                    rawSize := NumGet(sectionHeader + 0x10, "UInt")     
                    characteristics := NumGet(sectionHeader + 0x24, "UInt")
                    
                    FileAppend("`nProcessing section: " . sectionName . "`n", "ntdll_debug.log")
                    FileAppend("  Virtual Address: 0x" . Format("{:X}", virtualAddress) . "`n", "ntdll_debug.log")
                    FileAppend("  Virtual Size: 0x" . Format("{:X}", virtualSize) . "`n", "ntdll_debug.log")
                    FileAppend("  Raw Address: 0x" . Format("{:X}", rawAddress) . "`n", "ntdll_debug.log")
                    FileAppend("  Raw Size: 0x" . Format("{:X}", rawSize) . "`n", "ntdll_debug.log")
                    FileAppend("  Characteristics: 0x" . Format("{:X}", characteristics) . "`n", "ntdll_debug.log")
                    
                    if (sectionName = ".text") {
                        FileAppend("Found .text section, attempting memory operations`n", "ntdll_debug.log")
                        
                        ; Memory protection change attempt
                        loop 3 {
                            oldProtect := 0
                            FileAppend("Attempt " . A_Index . " to change memory protection`n", "ntdll_debug.log")
                            
                            targetAddr := baseAddr + virtualAddress
                            sourceAddr := mappedView + rawAddress  ; 
                            
                            FileAppend("Target address: 0x" . Format("{:X}", targetAddr) . "`n", "ntdll_debug.log")
                            FileAppend("Source address: 0x" . Format("{:X}", sourceAddr) . "`n", "ntdll_debug.log")
                            
                            result := DllCall("VirtualProtect",
                                "Ptr", targetAddr,
                                "UInt", virtualSize,
                                "UInt", 0x40,  ; PAGE_EXECUTE_READWRITE
                                "UInt*", &oldProtect)
                                
                            if (result) {
                                FileAppend("Successfully changed protection to RWX`n", "ntdll_debug.log")
                                FileAppend("Old protection was: 0x" . Format("{:X}", oldProtect) . "`n", "ntdll_debug.log")
                                
                                ; memory copy chunks
                                try {
                                    chunkSize := 4096  ; Copy in 4KB chunks
                                    totalSize := Min(virtualSize, rawSize)
                                    
                                    loop Floor(totalSize / chunkSize) {
                                        offset := (A_Index - 1) * chunkSize
                                        DllCall("RtlCopyMemory",
                                            "Ptr", targetAddr + offset,
                                            "Ptr", sourceAddr + offset,
                                            "UInt", chunkSize)
                                        
                                        FileAppend("Copied chunk " . A_Index . "`n", "ntdll_debug.log")
                                    }
                                    
                                    ; Copy remaining bytes
                                    remainingBytes := totalSize & 4095
                                    if (remainingBytes > 0) {
                                        offset := totalSize - remainingBytes
                                        DllCall("RtlCopyMemory",
                                            "Ptr", targetAddr + offset,
                                            "Ptr", sourceAddr + offset,
                                            "UInt", remainingBytes)
                                        FileAppend("Copied remaining " . remainingBytes . " bytes`n", "ntdll_debug.log")
                                    }
                                    
                                    FileAppend("Memory copy completed`n", "ntdll_debug.log")
                                    
                                } catch as err {
                                    FileAppend("Error during memory copy: " . err.Message . "`n", "ntdll_debug.log")
                                }
                                
                                ; Restore protection
                                restoreResult := DllCall("VirtualProtect",
                                    "Ptr", targetAddr,
                                    "UInt", virtualSize,
                                    "UInt", oldProtect,
                                    "UInt*", &oldProtect)
                                    
                                FileAppend("Protection restored: " . (restoreResult ? "Success" : "Failed") . "`n", "ntdll_debug.log")
                                
                                ; Memory barrier
                                DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
                                break
                            } else {
                                lastError := A_LastError
                                FileAppend("Failed to change protection. Error: " . lastError . "`n", "ntdll_debug.log")
                            }
                            Sleep(100)
                        }
                    }
                } catch as err {
                    FileAppend("Error processing section " . A_Index . ": " . err.Message . "`n", "ntdll_debug.log")
                }
            }
        } catch as err {
            FileAppend("Critical error in PE header processing: " . err.Message . "`n", "ntdll_debug.log")
            throw err
        }
        FileAppend("PE header processing completed`n", "ntdll_debug.log")
    }

    _ReadSectionName(sectionHeader) {
        name := ""
        loop 8 {
            char := Chr(NumGet(sectionHeader + A_Index - 1, "UChar"))
            if (Ord(char) = 0)
                break
            name .= char
        }
        return name
    }

    _ApplyCleanSection(baseAddr, mappedView, virtualAddress, virtualSize) {
        oldProtect := 0
        
        ; Change protection
        if (!DllCall("VirtualProtect",
            "Ptr", baseAddr + virtualAddress,
            "UInt", virtualSize,
            "UInt", 0x40,  ; PAGE_EXECUTE_READWRITE
            "UInt*", &oldProtect)) {
            this.LogWrite("Failed to change memory protection")
            return false
        }
        
        ; Copy clean section
        DllCall("RtlCopyMemory",
            "Ptr", baseAddr + virtualAddress,
            "Ptr", mappedView + virtualAddress,
            "UInt", virtualSize)
        
        ; Restore protection
        DllCall("VirtualProtect",
            "Ptr", baseAddr + virtualAddress,
            "UInt", virtualSize,
            "UInt", oldProtect,
            "UInt*", &oldProtect)
        
        ; Memory barrier
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
    }

    _CleanupHandles() {
        if (this.hNTDLL) {
            this.hNTDLL := 0
        }

        ; flush cached instructions
        DllCall("FlushInstructionCache", "Ptr", -1, "Ptr", 0, "UInt", 0)
        Sleep(100)  ; Give system time to stabilize
    }

    HandleUnhookNTDLL(*) {
        this.LogWrite("Starting unhook sequence...")
        
        ; Clean up any existing modifications first
        if (this.isModified) {
            this._CleanupHandles()
            this.isModified := false
            Sleep(100)  ; Give system time to stabilize
        }
        
        ; Then proceed with unhooking
        loop 3 {
            if (this.SafeInitialize()) {
                this.LogWrite("Successfully unhooked NTDLL")
                return true
            }
            this.LogWrite("Initialize attempt " . A_Index . " failed, retrying...")
            Sleep(1000)
        }
        
        this.LogWrite("All Initialize attempts failed")
        return false
    }

    ; Memory management functions
    _SaveCurrentState() {
        state := {
            baseAddress: 0,
            size: 0,
            protection: 0,
            handles: this._SaveCurrentHandles()
        }
        return state
    }

    _RestoreState(state) {
        if (!IsObject(state)) {
            return false
        }
        
        if (state.baseAddress != 0) {
            oldProtect := 0
            DllCall("VirtualProtect",
                "Ptr", state.baseAddress,
                "UInt", state.size,
                "UInt", state.protection,
                "UInt*", &oldProtect)
        }
        
        return this._RestoreHandles(state.handles)
    }

    _SaveCurrentHandles() {
        return {
            NTDLL: this.hNTDLL,
            Process: DllCall("GetCurrentProcess", "Ptr")
        }
    }

    _RestoreHandles(handles) {
        if (!IsObject(handles)) {
            return false
        }
        
        this.hNTDLL := handles.NTDLL
        return true
    }

    ; Protection functions
    _SetMemoryProtection(address, size, newProtection) {
        oldProtect := 0
        result := DllCall("VirtualProtect",
            "Ptr", address,
            "UInt", size,
            "UInt", newProtection,
            "UInt*", &oldProtect)
            
        return { success: result != 0, oldProtection: oldProtect }
    }

    _EnsureMemoryAccess(address, size) {
        ; Try to ensure memory access with retries
        loop 3 {
            result := this._SetMemoryProtection(address, size, 0x40)  ; PAGE_EXECUTE_READWRITE
            if (result.success) {
                return result
            }
            Sleep(100)
        }
        return { success: false, oldProtection: 0 }
    }

    ; Helper functions
    _GetErrorMessage(code) {
        ERROR_CODES := Map(
            2224, "The specified user account already exists.",
            2245, "The password does not meet the password policy requirements.",
            2226, "The user name or group name parameter is too long.",
            2202, "The specified username is invalid.",
            1378, "The specified local group already exists.",
            5, "Access denied.",
            87, "Invalid parameter.",
            8, "Not enough memory.",
            123, "Invalid name.",
            124, "Invalid level."
        )
        
        return ERROR_CODES.Has(code) ? ERROR_CODES[code] : "Unknown error (" . code . ")"
    }

    _VerifyMemoryContents(address, size, expected) {
        buff1 := Buffer(size, 0)
        bytesRead := 0
        
        result := DllCall("ReadProcessMemory",
            "Ptr", DllCall("GetCurrentProcess", "Ptr"),
            "Ptr", address,
            "Ptr", buff1.Ptr,
            "UInt", size,
            "UInt*", &bytesRead)
            
        if (!result || bytesRead != size) {
            return false
        }
        
        loop size {
            if (NumGet(buff1, A_Index-1, "UChar") != NumGet(expected, A_Index-1, "UChar")) {
                return false
            }
        }
        
        return true
    }

    _GetModuleInformation(moduleHandle) {
        ; Try PSAPI first
        moduleInfo := Buffer(24, 0)  ; sizeof(MODULEINFO)
        
        result := DllCall("psapi\GetModuleInformation",
            "Ptr", DllCall("GetCurrentProcess", "Ptr"),
            "Ptr", moduleHandle,
            "Ptr", moduleInfo.Ptr,
            "UInt", moduleInfo.Size)
            
        if (!result) {
            ; Try K32GetModuleInformation as fallback
            result := DllCall("kernel32\K32GetModuleInformation",
                "Ptr", DllCall("GetCurrentProcess", "Ptr"),
                "Ptr", moduleHandle,
                "Ptr", moduleInfo.Ptr,
                "UInt", moduleInfo.Size)
        }
        
        if (!result) {
            return {baseAddr: moduleHandle, size: 0, entryPoint: 0}
        }
        
        return {
            baseAddr: NumGet(moduleInfo, 0, "Ptr"),
            size: NumGet(moduleInfo, A_PtrSize, "UInt"),
            entryPoint: NumGet(moduleInfo, A_PtrSize + 4, "Ptr")
        }
    }

    _CrashLog(message, lastDLLError := 0) {
        errorMsg := "CRASH LOG - " . FormatTime(, "HH:mm:ss") . "`n"
        errorMsg .= "Message: " . message . "`n"
        if (lastDLLError) {
            errorMsg .= "LastDLLError: 0x" . Format("{:X}", lastDLLError) . "`n"
        }
        this.LogWrite(errorMsg)
    }

    _IsValidPtr(ptr) {
        return ptr && ptr != 0 && !(ptr & 0xFFFF000000000000)  ; Basic pointer validation
    }

    _AlignToPage(size) {
        PAGE_SIZE := 4096
        return (size + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1)
    }

    ; Debug helper
    _DumpMemoryToFile(address, size, filename := "memory_dump.bin") {
        try {
            buff1 := Buffer(size, 0)
            bytesRead := 0
            
            if (DllCall("ReadProcessMemory",
                "Ptr", DllCall("GetCurrentProcess", "Ptr"),
                "Ptr", address,
                "Ptr", buff1.Ptr,
                "UInt", size,
                "UInt*", &bytesRead)) {
                    
                file := FileOpen(filename, "w")
                if (file) {
                    file.RawWrite(buff1, size)
                    file.Close()
                    this.LogWrite("Memory dump saved to: " . filename)
                    return true
                }
            }
        } catch as err {
            this.LogWrite("Error during memory dump: " . err.Message)
        }
        return false
    }

    _GetWindowsErrorMessage(errorCode) {
        ; Allocate buffer for error message
        flags := 0x00001000  ; FORMAT_MESSAGE_FROM_SYSTEM
        languageId := 0       ; Default language
        
        ; Create a buffer to store the error message
        size := 1024
        buff1 := Buffer(size)
        
        ; Get the error message
        DllCall("FormatMessage",
            "UInt", flags,
            "Ptr", 0,
            "UInt", errorCode,
            "UInt", languageId,
            "Ptr", buff1.Ptr,
            "UInt", size,
            "Ptr", 0)
        
        ; Convert buffer to string
        return StrGet(buff1.Ptr)
    }

}

; Create instance
manipulator := NTDLLManipulator()