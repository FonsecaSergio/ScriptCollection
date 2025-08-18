<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2025-08-18

.SYNOPSIS   
    LIST FABRIC WORKSPACE

.DESCRIPTION
    This script lists Fabric workspace.
    Uses MicrosoftPowerBIMgmt MODULE
#> 

$workspaceId = "your-workspace-id-here"

########################################################################################################
#Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force

Import-Module MicrosoftPowerBIMgmt

########################################################################################################
Connect-PowerBIServiceAccount

$BearerToken = (Get-PowerBIAccessToken -AsString)

# Set headers with the token
$headers = @{
    'Authorization' = "$BearerToken"
    'Content-Type'  = 'application/json'
}
########################################################################################################
#https://learn.microsoft.com/en-us/rest/api/fabric/warehouse/items/list-warehouses

#GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/warehouses

$response = $null
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/warehouses"
Write-Host ($uri) -ForegroundColor Yellow

$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET

Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan

