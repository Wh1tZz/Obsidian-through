Option Explicit

Dim shell, command, i

If WScript.Arguments.Count = 0 Then
    WScript.Quit 1
End If

command = QuoteIfNeeded(WScript.Arguments(0))
For i = 1 To WScript.Arguments.Count - 1
    command = command & " " & QuoteIfNeeded(WScript.Arguments(i))
Next

Set shell = CreateObject("WScript.Shell")
shell.Run command, 0, True

Function QuoteIfNeeded(value)
    If InStr(value, " ") > 0 Or InStr(value, Chr(34)) > 0 Then
        QuoteIfNeeded = Chr(34) & Replace(value, Chr(34), "\" & Chr(34)) & Chr(34)
    Else
        QuoteIfNeeded = value
    End If
End Function
