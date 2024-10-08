#Requires AutoHotkey v2.0

; Get the current working directory for the output file
currentDir := A_ScriptDir
outputFile := currentDir "\output.txt"

; Define the time delay (24 hours from now)
futureTime := DateAdd(A_Now, 24, "hours")

; Split the date and time
dateTime := StrSplit(FormatTime(futureTime, "yyyy/MM/dd HH:mm"), " ")

if (dateTime.Length != 2) {
    FileAppend("Error splitting the date and time.`n", outputFile)
    ExitApp
}

; Split the date into its components
dateParts := StrSplit(dateTime[1], "/")

if (dateParts.Length != 3) {
    FileAppend("Error splitting the date into components.`n", outputFile)
    ExitApp
}

; Format the date and time for the scheduled task
formattedDate := dateParts[2] "/" dateParts[3] "/" dateParts[1]
formattedTime := SubStr(dateTime[2], 1, 5)

; Define the task name and the executable to run
taskName := "ScheduledTaskTest1"
executable := "calc.exe"

; Create the scheduled task command
command := Format('SCHTASKS /CREATE /SC ONCE /TN "{1}" /TR "{2}" /ST {3} /SD {4} /RU "SYSTEM" /F',
                  taskName, executable, formattedTime, formattedDate)

; Debugging: Write the command to the output file
FileAppend("Command: " command "`n", outputFile)

; Run the command
try {
    RunWait(A_ComSpec ' /c ' command ' > "' outputFile '" 2>&1',, "Hide")
    FileAppend("Scheduled task created to run calc.exe after 24 hours.`n", outputFile)
} catch as err {
    FileAppend("Error creating the scheduled task: " err.Message "`n", outputFile)
}

ExitApp