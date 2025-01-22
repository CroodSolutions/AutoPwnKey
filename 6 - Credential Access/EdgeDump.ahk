#Requires AutoHotkey v2.0

BackupEdgeData(backupRoot := "C:\tmp") {
    ; Set paths
    edgeDataPath := "C:\Users\" A_UserName "\AppData\Local\Microsoft\Edge\User Data"
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmm")
    backupPath := backupRoot "\edgeBackup_" timestamp
    
    DirCreate(backupPath)
    
    ; Copy Directory function
    CopyDirectory(source, destination) {
        if !DirExist(source)
            return
            
        DirCreate(destination)
        
        ; Copy all files in the directory
        try {
            FileCopy(source "\*.*", destination)
        }
        
        ; Recursively copy subdirectories
        loop files source "\*.*", "D" {
            if (A_LoopFileName != "." && A_LoopFileName != "..")
                CopyDirectory(source "\" A_LoopFileName, destination "\" A_LoopFileName)
        }
    }
    
    try {
        ; Backup default profile
        CopyDirectory(edgeDataPath "\Default", backupPath "\Default")
        
        ; Backup additional profiles
        loop files edgeDataPath "\Profile *", "D"
            CopyDirectory(edgeDataPath "\" A_LoopFileName, backupPath "\" A_LoopFileName)
        
        ; Backup Local State file (contains encryption key)
        FileCopy(edgeDataPath "\Local State", backupPath "\Local State", 1)
        
        return true
    }
    catch as err {
        return false
    }
}

; BackupEdgeData(path)    Backs up to target path  