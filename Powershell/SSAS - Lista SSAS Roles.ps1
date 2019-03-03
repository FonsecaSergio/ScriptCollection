<#

    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
    the object code form of the Sample Code, provided that You agree: 
    (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
    (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
    (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
    including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
    conditions contained within the Premier Customer Services Description.

#>

Clear-Host

## Import the SQL Server Module.
Import-Module "sqlps" -DisableNameChecking

$Server = New-Object Microsoft.AnalysisServices.Server


Try
{
    $Server.connect("localhost\SSAS");
    $Databases = $Server.databases;


    foreach ($database in $Databases)
    {
        Write-Output ("###########################################################################")
        Write-Output ("DATABASE: {0}" -f $database.Name)
        Write-Output ("###########################################################################")

        ###############################################################################################
        #ROLES
        ###############################################################################################
        $Roles = $database.Roles;

        foreach ($Role in $Roles)
        {
            #$DataSource | select * | Out-GridView;

            Write-Output ("")
            Write-Output ("---------------------------")
            Write-Output ("Role: {0}" -f $Role.Name)

            foreach ($Member in $Role.Members)
            {
                Write-Output ("Member: {0} - SID: {1}" -f $Member.Name, $Member.Sid)
            }

            #$Role | select * | Out-GridView
            #Write-Output ("Role: {0}" -f $Role.Name)


        
        }

        ###############################################################################################
        #DB PERMISSION
        ###############################################################################################
        Write-Output ("")
        Write-Output ("###########################################################################")
        Write-Output ("DatabasePermissions")
        Write-Output ("###########################################################################")
        
        foreach ($DatabasePermission in $DatabasePermissions)
        {
            Write-Output ("Role: {0} - Administer: {1} - Process: {2} - ReadDefinition: {3} - Read: {4} - Write: {5}" -f $DatabasePermission.Role, $DatabasePermission.Administer, $DatabasePermission.Process, $DatabasePermission.ReadDefinition, $DatabasePermission.Read, $DatabasePermission.Write)
        }

        ###############################################################################################
        #CUBE PERMISSION
        ###############################################################################################
        foreach ($Cube in $database.Cubes)
        {
            Write-Output ("")
            Write-Output ("###########################################################################")
            Write-Output ("Cube: {0}" -f $Cube.Name)
            Write-Output ("###########################################################################")

            #$CubePermissions = $Cube.CubePermissions
            #$CubePermissions | select Role, ReadSourceData, <#DimensionPermissions , CellPermissions#>, Process, ReadDefinition, Read, Write


            foreach ($CubePermission in $Cube.CubePermissions)
            {
                Write-Output ("")                
                Write-Output ("---------------------------")
                Write-Output ("CubePermissions")
                Write-Output ("---------------------------")
                Write-Output ("Role: {0} - ReadSourceData: {1} - Process: {2} - ReadDefinition: {3} - Read: {4} - Write: {5}" -f $CubePermission.Role, $CubePermission.ReadSourceData, $CubePermission.Process, $CubePermission.ReadDefinition, $CubePermission.Read, $CubePermission.Write)


                ###############################################################################################
                #CELL PERMISSION
                ###############################################################################################
                Write-Output ("")  
                Write-Output ("---------------------------")
                Write-Output ("CellPermission")
                Write-Output ("---------------------------")
                foreach ($CellPermission in $CubePermission.CellPermissions)
                {
                    Write-Output ("Access: {0} - Expression: ""{1}""" -f $CellPermission.Access, $CellPermission.Expression)                    
                }

                <#
                ###############################################################################################
                #DIMENSION DATA PERMISSION
                ###############################################################################################
                foreach ($DimensionPermission in $CubePermission.DimensionPermissions)
                {
                    
                    Write-Output ("------------------------------------------------------------------------------------------------------------")
                    Write-Output ("DimensionPermissions: Access: {0} - Expression: ""{1}""" -f $DimensionPermission.Access, $DimensionPermission.Expression)
                    Write-Output ("------------------------------------------------------------------------------------------------------------")                    
                    
                    $DimensionPermission | select *
                }
                #>

            }

            ###############################################################################################
            #DIMENSION PERMISSION
            ###############################################################################################
            foreach ($Dimension in $Cube.Dimensions)
            {
                Write-Output ("")  
                Write-Output ("###########################################################################")
                Write-Output ("Dimension: {0}" -f $Dimension.Name)
                Write-Output ("###########################################################################")
                foreach ($DimensionPermission in $Dimension.Dimension.DimensionPermissions)
                {
                    Write-Output ("Role: {0} - AllowedRowsExpression: {1} - Process: {2} - ReadDefinition: {3} - Read: {4} - Write: {5}" -f $DimensionPermission.Role, $DimensionPermission.AllowedRowsExpression, $DimensionPermission.Process, $DimensionPermission.ReadDefinition, $DimensionPermission.Read, $DimensionPermission.Write)

                                       
                    foreach ($AttributePermissions in $DimensionPermission.AttributePermissions)
                    {
                        foreach ($AttributePermission in $AttributePermissions)
                        {
                            Write-Output ("AttributePermissions: Role: {0} - Attribute: {1} - AllowedSet: {2}- DeniedSet: {3}- DefaultMember: {4}- VisualTotals: {5}" -f $DimensionPermission.Role, $AttributePermission.Attribute, $AttributePermission.AllowedSet, $AttributePermission.DeniedSet, $AttributePermission.DefaultMember, $AttributePermission.VisualTotals)
                        }

                        $AttributePermission | select AllowedSet, DeniedSet, DefaultMember, VisualTotals, Attribute

                    }
                    
                }

                
            }

 
        }

        


   
    }

    $Server.Disconnect();
}
Catch
{
    Write-Warning "$_"
}

