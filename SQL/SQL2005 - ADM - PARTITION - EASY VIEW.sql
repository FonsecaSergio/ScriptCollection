CREATE FUNCTION dbo.index_name (@object_id int, @index_id tinyint) 
RETURNS sysname 
AS 
BEGIN 
  DECLARE @index_name sysname 
  SELECT @index_name = name FROM sys.indexes 
     WHERE object_id = @object_id and index_id = @index_id 
  RETURN(@index_name) 
END;

GO
-- Written by Kalen Delaney, 2008 
--   with a few nice enhancements by Chad Crawford, 2009
CREATE VIEW Partition_Info AS 
  SELECT OBJECT_NAME(i.object_id) as Object_Name, dbo.INDEX_NAME(i.object_id,i.index_id) AS Index_Name, 
    p.partition_number, fg.name AS Filegroup_Name, rows, 
    au.total_pages, 
    CASE boundary_value_on_right 
        WHEN 1 THEN 'less than' 
        ELSE 'less than or equal to' 
    END as 'comparison' 
    , rv.value, 
    CASE WHEN ISNULL(rv.value, rv2.value) IS NULL THEN 'N/A' 
    ELSE 
      CASE 
        WHEN boundary_value_on_right = 0 AND rv2.value IS NULL  
           THEN 'Greater than or equal to' 
        WHEN boundary_value_on_right = 0 
           THEN 'Greater than' 
        ELSE 'Greater than or equal to' END + ' ' + 
           ISNULL(CONVERT(varchar(15), rv2.value), 'Min Value') 
                + ' ' + 
                + 
           CASE boundary_value_on_right 
             WHEN 1 THEN 'and less than' 
               ELSE 'and less than or equal to' 
               END + ' ' + 
                + ISNULL(CONVERT(varchar(15), rv.value), 
                           'Max Value') 
        END as 'TextComparison' 
  FROM sys.partitions p 
    JOIN sys.indexes i 
      ON p.object_id = i.object_id and p.index_id = i.index_id 
    LEFT JOIN sys.partition_schemes ps 
      ON ps.data_space_id = i.data_space_id 
    LEFT JOIN sys.partition_functions f 
      ON f.function_id = ps.function_id 
    LEFT JOIN sys.partition_range_values rv 
      ON f.function_id = rv.function_id 
          AND p.partition_number = rv.boundary_id     
    LEFT JOIN sys.partition_range_values rv2 
      ON f.function_id = rv2.function_id 
          AND p.partition_number - 1= rv2.boundary_id 
    LEFT JOIN sys.destination_data_spaces dds 
      ON dds.partition_scheme_id = ps.data_space_id 
          AND dds.destination_id = p.partition_number 
    LEFT JOIN sys.filegroups fg 
      ON dds.data_space_id = fg.data_space_id 
    JOIN sys.allocation_units au 
      ON au.container_id = p.partition_id 
WHERE i.index_id <2 AND au.type =1
GO
-- Example of use: 
SELECT * FROM Partition_Info 
WHERE Object_Name = 'Table_PART' 
ORDER BY Object_Name, partition_number