#Requires AutoHotkey v2.0

documentsPath := A_MyDocuments
contextLength := 30
results := ""

; Regex patterns
Regex1 := "\(?\d{3}\)?[ .-]\d{3}[ .-]\d{4}"
Regex2 := "\b\d{3}-\d{2}-\d{4}\b"
Regex3 := "\b(?:\d{1,2}[-/]\d{1,2}[-/]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})\b"

fileList := []
Loop Files, documentsPath "\*.txt", "R"
{
    fileList.Push(A_LoopFilePath)
}

outputFilePath := A_ScriptDir "\output.txt"
if FileExist(outputFilePath)
    FileDelete(outputFilePath)

if fileList.Length = 0
{
    FileAppend("Error: No .txt files found.`r`n", outputFilePath)
    ExitApp
}

for filePath in fileList
{
    try
    {
        fileContent := FileRead(filePath)
    }
    catch
    {
        continue
    }

    patterns := [Regex1, Regex2, Regex3]
    for pattern in patterns
    {
        fileResults := FindContext(fileContent, pattern, contextLength)
        AddResults(&results, filePath, fileResults)
    }
}

; Write the results to a text file
FileAppend(results, outputFilePath)

FindContext(content, pattern, length) {
    resultArray := []
    startPos := 1

    while (foundPos := RegExMatch(content, pattern, &match, startPos))
    {
        matchStr := match[]
        contextStart := foundPos + StrLen(matchStr)
        context := SubStr(content, contextStart, length)
        resultArray.Push(matchStr ": " context)
        startPos := contextStart
    }

    return resultArray
}

AddResults(&results, filePath, fileResults) {
    for result in fileResults
    {
        results .= filePath ": " result "`r`n"
    }
}
