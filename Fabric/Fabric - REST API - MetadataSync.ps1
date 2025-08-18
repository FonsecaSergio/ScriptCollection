<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2025-08-18

.SYNOPSIS   
    REFRESH SQL ENDPOINT METADATA FABRIC WORKSPACE 

.DESCRIPTION
    This script refreshes the metadata for a specific SQL endpoint within a Fabric workspace.
#> 

$workspaceId = "your-workspace-id-here"
$sqlEndpointId = "your-sql-endpoint-id-here"

########################################################################################################
az login

########################################################################################################

$token = (az account get-access-token --resource "https://api.fabric.microsoft.com/" | ConvertFrom-Json).accessToken

# Set headers with the token
$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type'  = 'application/json'
}
########################################################################################################
# List SQL Endpoints
########################################################################################################
#https://learn.microsoft.com/en-us/rest/api/fabric/sqlendpoint/items/list-sql-endpoints?tabs=HTTP

#GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/sqlEndpoints

$response = $null
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/sqlEndpoints"
Write-Host ($uri) -ForegroundColor Yellow

$webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method GET
$response = $webResponse.Content | ConvertFrom-Json
Write-Host "Status Code: $($webResponse.StatusCode)" -ForegroundColor Green

Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan

########################################################################################################
# Refresh SQL Endpoint Metadata
########################################################################################################
#https://learn.microsoft.com/en-us/rest/api/fabric/sqlendpoint/items/refresh-sql-endpoint-metadata

#POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/sqlEndpoints/{sqlEndpointId}/refreshMetadata

$response = $null
$uri = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/sqlEndpoints/$sqlEndpointId/refreshMetadata"
Write-Host ($uri) -ForegroundColor Yellow

$webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method POST -Body "{}"
$response = $webResponse.Content | ConvertFrom-Json
Write-Host "Status Code: $($webResponse.StatusCode)" -ForegroundColor Green

Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan


########################################################################################################
# Refresh SQL Endpoint Metadata LRO - NOT TESTED
########################################################################################################
#https://learn.microsoft.com/en-us/rest/api/fabric/core/long-running-operations/get-operation-state
#GET https://api.fabric.microsoft.com/v1/operations/b80e135a-adca-42e7-aaf0-59849af2ed78
#GET https://api.fabric.microsoft.com/v1/operations/b80e135a-adca-42e7-aaf0-59849af2ed78/result
if ($webResponse.StatusCode -eq 202) {
    $OperationId = $webResponse.Headers.'x-ms-operation-id'
    
    $response = $null
    $uri = "https://api.fabric.microsoft.com/v1/operations/$OperationId"
    Write-Host ($uri) -ForegroundColor Yellow

    $webResponse = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get
    $response = $webResponse.Content | ConvertFrom-Json
    Write-Host "Status Code: $($webResponse.StatusCode)" -ForegroundColor Green

    Write-Host ($response | ConvertTo-Json) -ForegroundColor Cyan
}



