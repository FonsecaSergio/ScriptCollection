<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2021-05-27

.SYNOPSIS   
Test connection using MSOLEDBSQL
   
.DESCRIPTION    
 
.PARAMETER xxxx 
       
#> 

Clear-Host

$DatabaseServer = "xxxxx.database.windows.net,1433"
$Database = "xxxxx"
$Username = "xxxxx"

if ($Password -eq $null) {
    $Password = Read-Host "Enter Pass" -AsSecureString
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))     
}
#Remove-Variable Password

#Get from KeyVault
#$Password = (Get-AzKeyVaultSecret -VaultName NameKeyVault -Name AzureSQLDBPassword).SecretValueText


#######################################################################################################################################################################################################################################################
$ConnectionTimeout = 15
$connectionString = "Provider=MSOLEDBSQL;Server=tcp:$DatabaseServer;Initial Catalog=$Database;Persist Security Info=False;User ID=$Username;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=$($ConnectionTimeout)"
$connection = New-Object -TypeName System.Data.OleDb.OleDbConnection($connectionString)

Write-Host "CurrentTime: $(((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd HH:mm:ss")) UTC"
Write-Host "Connection to Server ($($DatabaseServer)) / DB ($($Database)) / UserName ($($Username))"

Try{
    
    $connection.Open()    
    Write-Host "Connection with success ClientConnectionId($($connection.ClientConnectionId))"

    $command = New-Object -TypeName System.Data.OleDb.OleDbCommand
    $command.CommandTimeout = 60
    $command.Connection=$connection

    $command.CommandText = "Select getdate() as NOW"
    $result = $command.ExecuteScalar()    
    Write-Host "Query success. Server currenttime ($($result))"
    
    Start-Sleep -Seconds 60


    $connection.Close()


}
catch [System.Data.OleDb.OleDbException]
{
    $_.Exception.Errors[0] | Out-Host

    $ExceptionMessage = "SQL Exception: ($($_.Exception.Number)) / State: ($($_.Exception.State)) / $($_.Exception.Message)"    
    Write-Error $ExceptionMessage
    Write-Host "ClientConnectionId($($connection.ClientConnectionId))"
    Write-Host "Exception.ClientConnectionId ($($_.Exception.ClientConnectionId))"
}
Catch
{
    Write-Error $_.Exception.Message
}

