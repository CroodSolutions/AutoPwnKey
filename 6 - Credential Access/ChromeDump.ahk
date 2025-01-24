#Requires AutoHotkey v2.0

BackupChromeData(backupRoot := "C:\tmp") {
    ; Set paths
    chromeDataPath := "C:\Users\" A_UserName "\AppData\Local\Google\Chrome\User Data"
    timestamp := FormatTime(A_Now, "yyyyMMdd_HHmm")
    backupPath := backupRoot "\ChromeBackup_" timestamp
    
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
        CopyDirectory(chromeDataPath "\Default", backupPath "\Default")
        
        ; Backup additional profiles
        loop files chromeDataPath "\Profile *", "D"
            CopyDirectory(chromeDataPath "\" A_LoopFileName, backupPath "\" A_LoopFileName)
        
        ; Backup Local State file (contains encryption key)
        FileCopy(chromeDataPath "\Local State", backupPath "\Local State", 1)
        
        return true
    }
    catch as err {
        return false
    }
}

BackupChromeData(A_Desktop) ; Put your target backup location here. Using desktop as example
