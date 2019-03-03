#Require Powershell 7
$JSON = Get-ChildItem | ConvertTo-Json
$JSON | Set-Clipboard