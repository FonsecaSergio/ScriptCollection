/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-11-09
************************************************
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/create-use-external-tables
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-tables-external-tables?tabs=sql-on-demand
************************************************/

CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
WITH ( FORMAT_TYPE = PARQUET)
GO
CREATE EXTERNAL FILE FORMAT [SynapseCSVFormat]
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = ',',
          STRING_DELIMITER = '"',
          FIRST_ROW = 2, 
          USE_TYPE_DEFAULT = True)
)
GO

-----------------------------------
CREATE EXTERNAL DATA SOURCE SqlOnDemandDemo WITH (
    LOCATION = 'https://sqlondemandstorage.blob.core.windows.net'
);
GO

CREATE EXTERNAL TABLE dbo.Population (
    country_code VARCHAR (5) COLLATE Latin1_General_BIN2,
    country_name VARCHAR (100) COLLATE Latin1_General_BIN2,
    year smallint,
    population bigint
)  
WITH(   
        LOCATION = '/csv/population/population-*.csv',  
        DATA_SOURCE = SqlOnDemandDemo,  
        FILE_FORMAT = [SynapseCSVFormat]  
)
GO

--CREATE STATISTICS stat_country_name ON dbo.Population(country_name);
--Msg 15847, Level 16, State 1, Line 37
--Invalid DDL statement. Creating statistics for external tables requires FULLSCAN and NORECOMPUTE options. INCREMENTAL and MAXDOP options, as well as filter clause are not allowed.

CREATE STATISTICS stat_country_name ON dbo.Population(country_name) WITH FULLSCAN, NORECOMPUTE;
--Msg 15832, Level 16, State 1, Line 41
--Internal error number 13807 encountered while creating statistics.

SELECT 
    country_name, population
FROM population
WHERE year = 2019
ORDER BY population DESC
--Msg 13807, Level 16, State 1, Line 45
--Content of directory on path 'https://sqlondemandstorage.blob.core.windows.net/csv/population/population-*.csv' cannot be listed.




----------------------------
--CETAS


----------------------------
CREATE EXTERNAL DATA SOURCE LocalCovidData WITH (
    LOCATION = 'https://fonsecanetdatalake.blob.core.windows.net/'
);
GO

DROP EXTERNAL TABLE dbo.LocalCovidData_Portugal_CSV
GO
CREATE EXTERNAL TABLE dbo.LocalCovidData_Portugal_CSV
WITH(   
        LOCATION = '/fonsecanet/CSV/coviddataportugal/',  
        DATA_SOURCE = LocalCovidData,  
        FILE_FORMAT = [SynapseCSVFormat]  
)
AS
select GEO_ID, DATE_REP, CASES, DEATHS
from openrowset(bulk 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
                format='parquet') as a
where GEO_ID = 'PT'
order by DATE_REP
GO

SELECT * FROM dbo.LocalCovidData_Portugal_CSV
GO

----------------------------
DROP EXTERNAL TABLE dbo.LocalCovidData_Portugal_parquet
GO
CREATE EXTERNAL TABLE dbo.LocalCovidData_Portugal_parquet
WITH(   
        LOCATION = '/fonsecanet/Parquet/coviddataportugal/',  
        DATA_SOURCE = LocalCovidData,  
        FILE_FORMAT = [SynapseParquetFormat]  
)
AS
select GEO_ID, DATE_REP, CASES, DEATHS
from openrowset(bulk 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
                format='parquet') as a
where GEO_ID = 'PT'
order by DATE_REP
GO

CREATE STATISTICS st_LocalCovidData_Portugal_parquet_daterep ON LocalCovidData_Portugal_parquet(DATE_REP)
WITH FULLSCAN, NORECOMPUTE
GO

SELECT * FROM dbo.LocalCovidData_Portugal_parquet

GO