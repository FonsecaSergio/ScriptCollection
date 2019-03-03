Clear-Host;

#MUDA PRIMARY PARA INSTANCIA 1
Switch-SqlAvailabilityGroup -Path SQLSERVER:\Sql\SQL-AON-01\DEFAULT\AvailabilityGroups\AG-AON # -AllowDataLoss -Force

#MUDA PRIMARY PARA INSTANCIA 2
Switch-SqlAvailabilityGroup -Path SQLSERVER:\Sql\SQL-AON-02\DEFAULT\AvailabilityGroups\AG-AON

########################################################################################################################################################################
# HealthState - Meaning
# Error - The object is in a critical state, high availability has been compromised. 
# Warning - The object is in a warning state, high availability may be at risk.
# Unknown - The health of the object cannot be determined. This can occur if you execute these cmdlets on a secondary replica.
# PolicyExecutionFailure - An exception was thrown while evaluating a policy against this object. This can indicate an error in the implementation of the policy.
# Healthy - The object is in a healthy state.
########################################################################################################################################################################

#VERIFICA SAUDE GRUPOS
Get-ChildItem SQLSERVER:\Sql\SQL-AON-01\DEFAULT\AvailabilityGroups | Test-SqlAvailabilityGroup
Get-ChildItem SQLSERVER:\Sql\SQL-AON-02\DEFAULT\AvailabilityGroups | Test-SqlAvailabilityGroup

#VERIFICA SAUDE REPLICAS
Test-SqlAvailabilityReplica -Path SQLSERVER:\Sql\SQL-AON-01\DEFAULT\AvailabilityGroups\AG-AON\AvailabilityReplicas\SQL-AON-01
Test-SqlAvailabilityReplica -Path SQLSERVER:\Sql\SQL-AON-01\DEFAULT\AvailabilityGroups\AG-AON\AvailabilityReplicas\SQL-AON-02

#VERIFICA SAUDE BASES
Get-ChildItem SQLSERVER:\Sql\SQL-AON-01\DEFAULT\AvailabilityGroups\AG-AON\DatabaseReplicaStates | Test-SqlDatabaseReplicaState
Get-ChildItem SQLSERVER:\Sql\SQL-AON-02\DEFAULT\AvailabilityGroups\AG-AON\DatabaseReplicaStates | Test-SqlDatabaseReplicaState
