
try
{
    ########################################################################################################
    #Install Azure Powershell
    #   https://docs.microsoft.com/pt-br/powershell/azure/overview?view=azurermps-3.8.0
    
    $Powershell = Get-Module PowerShellGet -list | Select-Object Name,Version,Path
    if ($Powershell.Name -ne "PowerShellGet")
    {
        Set-ExecutionPolicy Unrestricted
        Install-Module AzureRM
    }
    #Update-Module -Name AzureRM -Force
    Import-Module AzureRM
    ########################################################################################################
    $InformationPreference = "continue"
    
    ########################################################################################################
    #Part 1 - Log in and set variables
    Login-AzureRmAccount 

    #Get-AzureRmSubscription

    Select-AzureRmSubscription -SubscriptionName "Microsoft Azure Internal Consumption"

    ########################################################################################################
    $ResourceGroups = Get-AzureRmResourceGroup

    if ($ResourceGroups -eq $null)
    {
        Write-Information "No resource groups to DELETE"
    }
    else
    {
        $ResourceGroups | select ResourceGroupName | Out-Host

        foreach ($ResourceGroup in $ResourceGroups) 
        {
            $ResourceGroupName = $ResourceGroup.ResourceGroupName
            Write-Information ("DELETING RESOURCE GROUP ($ResourceGroupName)")

            Remove-AzureRmResourceGroup -Name $ResourceGroupName
        }
    }
}
catch
{
    write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    write-host "--->$($_.Exception.Message)" -ForegroundColor Red
}
finally
{

}