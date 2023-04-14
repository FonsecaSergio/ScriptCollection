
cd "C:\Sergio\Dropbox\Documents\ScriptCollection\Powershell"


#TEST SYNAPSE + API CALLS
.\Synapse-TestConnection_dev.ps1 -WorkspaceName "fonsecanetsynapse" -SubscriptionID "de41dc76-12ed-4406-a032-0c96495def6b" -TryToConnect_YorN "Y"

#TEST SYNAPSE + NO API CALLS
.\Synapse-TestConnection_dev.ps1 -WorkspaceName "fonsecanetsynapse" -SubscriptionID "de41dc76-12ed-4406-a032-0c96495def6b" -TryToConnect_YorN "N"

#TEST FORMERDW + API CALLS
.\Synapse-TestConnection_dev.ps1 -WorkspaceName "fonsecanet" -SubscriptionID "de41dc76-12ed-4406-a032-0c96495def6b" -TryToConnect_YorN "N"

#TEST SYNAPSE + DEP + API CALLS
.\Synapse-TestConnection_dev.ps1 -WorkspaceName "fonsecanetsynapsedep" -SubscriptionID "de41dc76-12ed-4406-a032-0c96495def6b" -TryToConnect_YorN "Y"

#TEST incorrect subscription id (XX at end)
.\Synapse-TestConnection_dev.ps1 -WorkspaceName "fonsecanetsynapsedep" -SubscriptionID "de41dc76-12ed-4406-a032-0c96495defXX" -TryToConnect_YorN "Y"
