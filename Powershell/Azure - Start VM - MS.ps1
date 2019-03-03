#Gerar publishsettings
#Get-AzurePublishSettingsFile

Import-AzurePublishSettingsFile -PublishSettingsFile "C:\TEMP\Visual Studio Ultimate com MSDN - Microsoft-credentials.publishsettings"

Start-AzureVM -ServiceName "FonsecanetSQL2014" -Name "SQL2014";
Start-Sleep -s 15 #DELAY POR CAUSA DO AD
Start-AzureVM -ServiceName "SQL-AON"           -Name "SQL-AON-01";
Start-AzureVM -ServiceName "SQL-AON"           -Name "SQL-AON-02";
Start-AzureVM -ServiceName "FonsecanetAD"      -Name "FonsecanetAD";

