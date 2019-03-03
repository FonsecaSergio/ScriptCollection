DROP TABLE PartitionTable
DROP PARTITION SCHEME myRangePS1
DROP PARTITION FUNCTION myRangePF1


-- Creates a partition function called myRangePF1 that will partition a table into four partitions
CREATE PARTITION FUNCTION myRangePF1 (int)
    AS RANGE LEFT FOR VALUES (1, 100, 1000) ;
GO
-- Creates a partition scheme called myRangePS1 that applies myRangePF1 to the four filegroups created above
CREATE PARTITION SCHEME myRangePS1
    AS PARTITION myRangePF1
    ALL TO ([PRIMARY]) ;
GO
-- Creates a partitioned table called PartitionTable that uses myRangePS1 to partition col1
--DROP TABLE PartitionTable
CREATE TABLE PartitionTable (col1 int PRIMARY KEY, col2 char(8000))
    ON myRangePS1 (col1) ;
GO

INSERT INTO PartitionTable VALUES (1,1),(100,100),(1000,1000),(1001,1001),(1002,1002),(1003,1003)

-- Example of use: 
SELECT * FROM Partition_Info 
WHERE Object_Name = 'PartitionTable' 
ORDER BY Object_Name, partition_number