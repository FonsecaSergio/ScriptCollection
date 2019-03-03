#Gerar publishsettings
#Get-AzurePublishSettingsFile

Import-AzurePublishSettingsFile -PublishSettingsFile "C:\TEMP\Visual Studio Ultimate com MSDN - Microsoft-credentials.publishsettings"

Stop-AzureVM -ServiceName "FonsecanetSQL2014" -Name "SQL2014" -Force;
Stop-AzureVM -ServiceName "SQL-AON"           -Name "SQL-AON-01" -Force;
Stop-AzureVM -ServiceName "SQL-AON"           -Name "SQL-AON-02" -Force;
Stop-AzureVM -ServiceName "FonsecanetAD"      -Name "FonsecanetAD" -Force;
