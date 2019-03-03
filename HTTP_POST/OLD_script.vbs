''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' VBscrip - POST::HTTP
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Autor: Sergio C Fonseca
' Data: 05/01/2006
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
	
	wscript.stdout.write "MESSAGE: " + oArgs.item(0) + CHR(10)
	wscript.stdout.write "MESSAGE: " + oArgs.item(1) + CHR(10)
	wscript.stdout.write "RESULT: " + txtResult + CHR(10)
	wscript.stdout.write "MESSAGE: OK" + CHR(10)
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