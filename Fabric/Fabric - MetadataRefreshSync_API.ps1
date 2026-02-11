<#   
.NOTES     
    Author: Sergio Fonseca
    Twitter @FonsecaSergio
    Email: sergio.fonseca@microsoft.com
    Last Updated: 2026-02-11

.SYNOPSIS   
    Refresh SQL analytics endpoint Metadata REST API

.DESCRIPTION
    REF: https://blog.fabric.microsoft.com/en-us/blog/refresh-sql-analytics-endpoint-metadata-rest-api-now-in-public-preview/
    REF: https://medium.com/@sqltidy/troubleshooting-md-sync-in-microsoft-fabric-87ed4930ddc1
#> 

# Bearer token only (no "Bearer " prefix here)
# Can get token from https://learn.microsoft.com/en-us/rest/api/fabric/sqlendpoint/items/refresh-sql-endpoint-metadata?tabs=HTTP&tryIt=true&source=docs#code-try-0

$token = ""
$workspaceId = "d946df5a-da75-487c-ae5b-971e9bbd6a38"
$sqlEndpointId = "89e04d29-6e66-40cd-97bc-979fe958b6df"

$uri = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/sqlEndpoints/$sqlEndpointId/refreshMetadata"

$headers = @{
  Authorization = "Bearer $token"
}

#$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json"
$response = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -UseBasicParsing

$response
