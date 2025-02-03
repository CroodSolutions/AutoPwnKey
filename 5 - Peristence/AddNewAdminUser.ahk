#Requires AutoHotkey v2.0

; Constants
UF_SCRIPT := 0x0001
UF_NORMAL_ACCOUNT := 0x0200

Log(msg, logFile := "logfile.txt") {
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    logMessage := timestamp " NetworkClient: " msg "`n"
    
    try {
        FileAppend(logMessage, "*")
    } catch Error as err {
        FileAppend(logMessage, logFile)
    }
}

hNetApi32 := DllCall("LoadLibrary", "Str", "Netapi32.dll", "Ptr")

; Requires admin
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; Error code mapping
ERROR_CODES := Map(
    2224, "The specified user account already exists.",
    2245, "The password does not meet the password policy requirements.",
    2226, "The user name or group name parameter is too long.",
    2202, "The specified username is invalid.",
    1378, "The specified local group already exists.",
    ERROR_ACCESS_DENIED := 5, "Access denied.",
    ERROR_INVALID_PARAMETER := 87, "Invalid parameter.",
    ERROR_NOT_ENOUGH_MEMORY := 8, "Not enough memory.",
    ERROR_INVALID_NAME := 123, "Invalid name.",
    ERROR_INVALID_LEVEL := 124, "Invalid level."
)

CreateLocalUser(username := "NewUser", password := "P@ssw0rd123!", fullname := "New Local User") {
    Log("Starting CreateLocalUser function")
    
    try {
        ; Test structure size
        structSize := A_PtrSize * 6 + 4 * 2  ; 6 pointers and 2 DWORDs
        Log("Calculated structure size: " structSize)
        
        userInfo := Buffer(structSize, 0)
        Log("Created userInfo buffer of size: " userInfo.Size)
        
        ; Test each offset before writing
        offsets := Map(
            "name", 0,
            "password", A_PtrSize,
            "password_age", A_PtrSize * 2,
            "priv", A_PtrSize * 2 + 4,
            "home_dir", A_PtrSize * 3,
            "comment", A_PtrSize * 4,
            "flags", A_PtrSize * 5,
            "script_path", A_PtrSize * 5 + 4
        )
        
        For field, offset in offsets {
            Log("Field '" field "' offset: " offset)
            if (offset + (InStr(field, "age") || InStr(field, "priv") || InStr(field, "flags") ? 4 : A_PtrSize) > structSize) {
                throw Error("Field '" field "' would exceed buffer size")
            }
        }
        
        ; Create and verify pointers
        usernamePtr := StrPtr(username)
        passwordPtr := StrPtr(password)
        
        Log("Writing structure fields...")
        NumPut("Ptr", usernamePtr,                userInfo, offsets["name"])
        NumPut("Ptr", passwordPtr,                userInfo, offsets["password"])
        NumPut("UInt", 0,                         userInfo, offsets["password_age"])
        NumPut("UInt", 1,                         userInfo, offsets["priv"])
        NumPut("Ptr", 0,                          userInfo, offsets["home_dir"])
        NumPut("Ptr", 0,                          userInfo, offsets["comment"])
        NumPut("UInt", UF_SCRIPT|UF_NORMAL_ACCOUNT, userInfo, offsets["flags"])
        NumPut("Ptr", 0,                          userInfo, offsets["script_path"])
        
        ; Verify structure before API call
        Log("Structure contents:")
        For field, offset in offsets {
            value := NumGet(userInfo, offset, InStr(field, "age") || InStr(field, "priv") || InStr(field, "flags") ? "UInt" : "Ptr")
            Log("  " field ": 0x" format("{:X}", value))
        }
        
        ; Prepare for API call
        parmError := Buffer(4, 0)
        
        Log("Calling NetUserAdd...")
        result := DllCall("Netapi32\NetUserAdd",
            "Ptr", 0,
            "UInt", 1,
            "Ptr", userInfo.Ptr,
            "Ptr", parmError.Ptr)
        
        if (result != 0) {
            lastError := DllCall("GetLastError")
            Log("API Error - Result: " result ", LastError: " lastError ", ParmError: " NumGet(parmError, 0, "UInt"))
            errorMessage := ERROR_CODES.Has(result) ? ERROR_CODES[result] : "Unknown error (" result ")"
            throw Error("Failed to create user: " errorMessage)
        }
        
        Log("User creation successful")
        MsgBox("User account created successfully.", "Success", "64")
        AddUserToAdminGroup(username)
        
    } catch Error as err {
        Log("Error: " err.Message)
        if (err.Extra)
            Log("Extra info: " err.Extra)
        MsgBox("Error creating user account: " err.Message, "Error", "16")
    }
}

AddUserToAdminGroup(username) {
    Log("Starting AddUserToAdminGroup for user: " username)
    
    try {
        ; Create LOCALGROUP_MEMBERS_INFO_3 structure (only contains domainandname field)
        memberInfo := Buffer(A_PtrSize, 0)  ; Size of one pointer
        
        ; Store the username pointer
        usernamePtr := StrPtr(username)
        NumPut("Ptr", usernamePtr, memberInfo, 0)
        
        Log("Calling NetLocalGroupAddMembers...")
        Log("  Username ptr: " format("0x{:X}", usernamePtr))
        Log("  Buffer ptr: " format("0x{:X}", memberInfo.Ptr))
        
        ; Call NetLocalGroupAddMembers
        result := DllCall("Netapi32\NetLocalGroupAddMembers",
            "Ptr", 0,                    ; servername (NULL = local)
            "Str", "Administrators",      ; groupname
            "UInt", 3,                   ; level (using LOCALGROUP_MEMBERS_INFO_3)
            "Ptr", memberInfo.Ptr,       ; buf
            "UInt", 1,                   ; totalentries (adding 1 member)
            "UInt")                      ; return type
        
        lastError := A_LastError
        Log("NetLocalGroupAddMembers result: " result)
        Log("LastError: " lastError)
        
        ; Check for specific error codes
        if (result = 0) {
            Log("Successfully added user to Administrators group")
        } else {
            errorMessage := ""
            switch result {
                case 1377:  ; ERROR_MEMBER_IN_ALIAS
                    errorMessage := "User is already a member of the group"
                case 1378:  ; NERR_GroupNotFound
                    errorMessage := "Administrators group not found"
                case 1387:  ; ERROR_NO_SUCH_MEMBER
                    errorMessage := "User account not found"
                case 1388:  ; ERROR_INVALID_MEMBER
                    errorMessage := "Invalid user account"
                case 5:     ; ERROR_ACCESS_DENIED
                    errorMessage := "Access denied"
                default:
                    errorMessage := "Unknown error: " result
            }
            throw Error("Failed to add user to Administrators group: " errorMessage, -1, result)
        }
        
    } catch Error as err {
        Log("Error adding user to group: " err.Message " (Code: " err.Extra ")")
        MsgBox("Error adding user to Administrators group:`n" err.Message, "Error", "16")
    }
}

; Create the user
Log "Script started"
CreateLocalUser()
Log "Script finished"

; Clean up
DllCall("FreeLibrary", "Ptr", hNetApi32)
ExitApp