Dim system
Dim newConfigurationString

newConfigurationString = Trim(InputBox("Digite o novo valor para ConfigurationString","IGC - Configuração"))

If (newConfigurationString = "") then
	MsgBox "O valor ConfigurationString deve se referir a localizção de um arquivo com extensão "".dtsConfig""",,"IGC - Configuração"
	Wscript.Quit
End If

Set system = CreateObject("Scripting.FileSystemObject")

Call SearchFiles(GetCurrentDirectory())

'*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Sub SearchFiles(directory)
    Dim file
    Dim folder
    Set folder = system.GetFolder(directory)
       For Each file In folder.Files
          If InStr(1,LCase(file.Name),".dtsx") > 1 Then
			SearchLine(file.Name)
          End If
       Next 
       
       MsgBox "Concluído",,"IGC - Configuração"
End Sub
'*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Sub SearchLine(fileName)
	Dim line
	Dim objFile
	Dim beginPosition
	Dim endPosition
	Dim pathInDTSX
	Set objFile = system.OpenTextFile(fileName, 1) 
	Do Until objFile.AtEndOfStream 
		line = objFile.ReadLine 
		If (InStr(1,UCase(line),".DTSCONFIG") > 1) Then
			objFile.Close 
			
			beginPosition = Instr(1,line,"<DTS:Property DTS:Name=""ConfigurationString"">",1) + Len("<DTS:Property DTS:Name=""ConfigurationString"">")
			endPosition = Instr(beginPosition,line,"</DTS:Property>",1)
			
			pathInDTSX = Mid(line,beginPosition,endPosition - beginPosition)
			Call ReplaceConfigurationString(fileName,pathInDTSX)
			Exit Sub
		End If
	Loop 
	MsgBox "Não foi encontrado no arquivo """ + fileName + """ nenhuma referência a extensão "".dtsConfig""" 
	objFile.Close 
End Sub
'*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Sub ReplaceConfigurationString(fileName, stringToReplace)
	Dim objFile
	Dim strText
	Const ForReading = 1
	Const ForWriting = 2

	Set objFile = system.OpenTextFile(fileName, ForReading)

	strText = objFile.ReadAll
	objFile.Close
	strNewText = Replace(strText, stringToReplace, newConfigurationString)

	Set objFile = system.OpenTextFile(fileName, ForWriting)
	objFile.WriteLine strNewText
	objFile.Close
End Sub
'*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Function GetCurrentDirectory() 
  	GetCurrentDirectory = left(WScript.ScriptFullName,(Len(WScript.ScriptFullName))-(len(WScript.ScriptName))) 
End Function