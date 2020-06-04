/*
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute 
the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indentify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
including attorneys' fees, that arise or result from the use or distribution of the Sample Code.

Please note: None of the conditions outlined in the disclaimer above will supersede the terms and 
conditions contained within the Premier Customer Services Description.

*/

--Sample Metadata queries

-- For Page or Key resources
SELECT 
 DB_ID(),
 object_name(p.object_id) as object_name
, i.name as index_name
, p.object_id
, p.index_id
, p.partition_number
FROM sys.partitions p
INNER JOIN sys.indexes i ON i.object_id = p.object_id
							AND i.index_id = p.index_id
WHERE p.hobt_id = 72057594045857792

-- For Page resources
DBCC TRACEON(3604)
GO
DBCC PAGE (6,1,791,3)
GO
DBCC TRACEOff(3604)

-- For Key resources
SELECT *
FROM Production.Product WITH(NOLOCK)
WHERE %%lockres%% COLLATE DATABASE_DEFAULT = '(61a06abd401c)' -- Key hash obtained from resource_description column
