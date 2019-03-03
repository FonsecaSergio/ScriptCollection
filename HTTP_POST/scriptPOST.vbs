''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' VBscrip - POST::HTTP
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Autor: Sergio C Fonseca
' Data: 05/01/2006
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
On Error resume Next

dim oArgs
set oArgs=wscript.arguments

IF oArgs.COUNT = 0 THEN
	wscript.stdout.write "MESSAGE: ERRO" + CHR(10)
ELSE
	Dim DataToSend
	Dim Server
	
	'Server = "http://tito:8080/Vosprepaid/Request.asp"
	'DataToSend = "action=login&user=adm&password=1234"

	Server = oArgs.item(0)
	DataToSend = oArgs.item(1)
	
	txtResult = sendinfo (Server, DataToSend)
	
	wscript.stdout.write "MESSAGE: Server =  " + Server  + CHR(10)
	wscript.stdout.write "MESSAGE: DataToSend = " + DataToSend + CHR(10)
	wscript.stdout.write "RESULT: " + txtResult + CHR(10)
	wscript.stdout.write "MESSAGE: OK" + CHR(10)
	
	LOG("SERVER = " + Server + " / DATATOSEND = " + DataToSend + " / RESULTADO = " + txtResult)

END IF

Function sendinfo (ByVal Server, ByVal DataToSend)
	Dim txtResult
	Dim myhttp

	Set myhttp=CreateObject("Msxml2.XMLHTTP")

	myhttp.open "POST", Server, false
	myhttp.setRequestHeader "lastCached", now()
	myhttp.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
	myhttp.send DataToSend
	txtResult = myhttp.responseText 
	set myhttp = Nothing
	sendinfo =  txtResult
end function

Function LOG (ByVal DataToLOG)
	Dim oFSO, sFileName, tf
	Const ForReading = 1, ForWriting = 2, ForAppending = 8 

	sFilename = "c:\VOXAGE\LOG_HTTPPOST_" + CSTR(Year(NOW)) + RIGHT("0" + CSTR(Month(NOW)),2) + RIGHT("0" + CSTR(Day(NOW)),2) +".txt"

	Set oFSO = CreateObject("Scripting.FileSystemObject")

	' Check for file and return appropriate result
	If oFSO.FileExists( sFilename ) Then
		Set tf = oFSO.OpenTextFile( sFilename , ForAppending , True)
	Else
		Set tf = oFSO.CreateTextFile( sFilename , True)
	End If

	tf.WriteLine( CSTR(NOW) + " - " + DataToLOG) 
	tf.Close
end function


