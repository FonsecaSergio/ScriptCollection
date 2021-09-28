/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-11-09
************************************************
--READING WITH OPENROWSET
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/develop-openrowset

--SAMPLE DATA SETS
--https://azure.microsoft.com/en-us/services/open-datasets/catalog/nyc-taxi-limousine-commission-yellow-taxi-trip-records/
--https://azure.microsoft.com/en-us/services/open-datasets/catalog/public-holidays/
--https://azure.microsoft.com/en-us/services/open-datasets/catalog/noaa-integrated-surface-data/

------------------------------------------------------------------------------
--CSV
--https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/query-single-csv-file

************************************************/

SELECT TOP 10 *
FROM OPENROWSET(
		BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.csv',
		FORMAT = 'csv',
		PARSER_VERSION ='2.0',
		FIRSTROW = 2
	) 
WITH (
	[date_rep] date 1,
	[cases] int 5,
	[geo_id] varchar(6) 8
) as [CASES]
WHERE [geo_id] = 'AF'

SELECT TOP 10 *
FROM OPENROWSET(
		BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.csv',
		FORMAT = 'csv',
		PARSER_VERSION ='2.0',
		FIRSTROW = 2
	) 
WITH (
	[date_rep] date 1,
	[cases] int 5,
	[geo_id] varchar(6) 8
) as [CASES]
WHERE [geo_id] = 'PT'

SELECT [geo_id]
FROM OPENROWSET(
		BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.csv',
		FORMAT = 'csv',
		PARSER_VERSION ='2.0',
		FIRSTROW = 2
	) 
WITH (
	[date_rep] date 1,
	[cases] int 5,
	[geo_id] varchar(6) 8
) as [CASES]
GROUP BY [geo_id]

--Statement ID: {5CE947C8-920F-42DB-853C-BF7CA4544FE4} | Query hash: 0x85788F294884524C | Distributed request ID: {D8952536-A9E5-4F6F-B5E1-9CAEF123DFF0}. Total size of data scanned is 5 megabytes, total size of data moved is 0 megabytes, total size of data written is 0 megabytes.
--Msg 15802, Level 16, State 14, Line 13
--Request to perform an external distributed computation has failed with error "[[Error handling external file: 'Max errors count reached.'. File: 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.csv'. (Number: 15813, Severity: 16, State: 1)]]".


SELECT TOP 100 *
FROM OPENROWSET(
		BULK 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.csv',
		FORMAT = 'csv',
		PARSER_VERSION ='2.0',
		FIRSTROW = 2
	) 
WITH (
	[date_rep] date 1,
	[cases] int 5,
	[geo_id] varchar(6) 8
) as [CASES]
WHERE [geo_id] = 'AF'


SELECT *
FROM OPENROWSET(
        BULK 'https://sqlondemandstorage.blob.core.windows.net/public-csv/population/population.csv',
        FORMAT = 'CSV', 
		PARSER_VERSION = '2.0',
        FIELDTERMINATOR =',',
        ROWTERMINATOR = '\n'
    )
WITH (
    [country_name] VARCHAR (100) COLLATE Latin1_General_BIN2 2,
    [year] smallint 3,
    [population] bigint 4
) AS [r]
WHERE
    [country_name] = 'Portugal'
    --AND [year] = 2017
ORDER BY [year] ASC

------------------------------------------------------------------------------
--PARQUET
GO

	------------------------------------------------------------------------------
	--VIEW https://docs.microsoft.com/en-us/azure/synapse-analytics/sql/create-use-views
	IF EXISTS (SELECT * FROM sys.views WHERE name = 'vwHolidayDataOpenrowset')
		DROP VIEW vwHolidayDataOpenrowset
	GO
	CREATE VIEW vwHolidayDataOpenrowset AS
		SELECT * FROM
			OPENROWSET(
				BULK 'https://azureopendatastorage.blob.core.windows.net/holidaydatacontainer/Processed/*.parquet',
				FORMAT='PARQUET'
			) AS [holidays]
	WHERE date BETWEEN CONCAT(YEAR(GETDATE()),'-01-01') AND CONCAT(YEAR(GETDATE())+2,'-12-31')
	GO
	SELECT * FROM vwHolidayDataOpenrowset
	WHERE CountryOrRegion = 'Portugal'
	GO
	------------------------------------------------------------------------------




SELECT TOP 1000 * FROM
    OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/holidaydatacontainer/Processed/*.parquet',
        FORMAT='PARQUET'
    ) AS [holidays]
WHERE CountryOrRegion = 'Portugal'
AND date >= '2020-01-01'

SELECT
    AVG(windspeed) AS avg_windspeed,
    MIN(windspeed) AS min_windspeed,
    MAX(windspeed) AS max_windspeed,
    AVG(temperature) AS avg_temperature,
    MIN(temperature) AS min_temperature,
    MAX(temperature) AS max_temperature,
    AVG(sealvlpressure) AS avg_sealvlpressure,
    MIN(sealvlpressure) AS min_sealvlpressure,
    MAX(sealvlpressure) AS max_sealvlpressure,
    AVG(precipdepth) AS avg_precipdepth,
    MIN(precipdepth) AS min_precipdepth,
    MAX(precipdepth) AS max_precipdepth,
    AVG(snowdepth) AS avg_snowdepth,
    MIN(snowdepth) AS min_snowdepth,
    MAX(snowdepth) AS max_snowdepth
FROM
    OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/isdweatherdatacontainer/ISDWeather/year=*/month=*/*.parquet',
        FORMAT='PARQUET'
    ) AS [weather]
WHERE countryorregion = 'US' AND CAST([datetime] AS DATE) = '2016-01-23' AND stationname = 'JOHN F KENNEDY INTERNATIONAL AIRPORT'

SELECT TOP 100 *
FROM OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
        FORMAT='PARQUET'
    ) AS [nyc];

--SELECT
--	YEAR(pickup_datetime) AS [year],
--	SUM(passenger_count) AS passengers_total,
--	COUNT(*) AS [rides_total]
--FROM OPENROWSET( 
--        BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
--        FORMAT = 'PARQUET')  AS nyc
--GROUP BY YEAR(pickup_datetime) 
--ORDER BY YEAR(pickup_datetime)

SELECT top 10
      r.filepath() AS [filepath]
	 ,r.filepath(1) AS [filepath1]
	 ,r.filepath(2) AS [filepath2]
	 ,r.filename() AS [filename]
FROM OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
        FORMAT = 'PARQUET') AS [r]

SELECT 
     r.filepath(1) AS [year]
    ,r.filepath(2) AS [month]
    ,COUNT_BIG(*) AS [rows]
FROM OPENROWSET(
        BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
        FORMAT = 'PARQUET') AS [r]
WHERE r.filepath(1) IN ('2017') 
     AND r.filepath(2) IN ('10', '11', '12')
GROUP BY    r.filepath() ,r.filepath(1) ,r.filepath(2)
ORDER BY    r.filepath




WITH taxi_rides AS
(
    SELECT
        CAST([tpepPickupDateTime] AS DATE) AS [current_day],
        COUNT(*) as rides_per_day
    FROM  
        OPENROWSET(
            BULK 'https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=*/puMonth=*/*.parquet',
            FORMAT='PARQUET'
        ) AS [nyc]
    WHERE nyc.filepath(1) = '2016'
    GROUP BY CAST([tpepPickupDateTime] AS DATE)
),
public_holidays AS
(
    SELECT
        holidayname as holiday,
        date
    FROM
        OPENROWSET(
            BULK 'https://azureopendatastorage.blob.core.windows.net/holidaydatacontainer/Processed/*.parquet',
            FORMAT='PARQUET'
        ) AS [holidays]
    WHERE countryorregion = 'United States' AND YEAR(date) = 2016
)
SELECT
*
FROM taxi_rides t
LEFT OUTER JOIN public_holidays p on t.current_day = p.date
ORDER BY current_day ASC

------------------------------------------------------------------------------
--JSON
SELECT TOP 10 *
    JSON_VALUE(jsonContent, '$.countryCode') AS country_code,
    JSON_VALUE(jsonContent, '$.countryName') AS country_name,
    JSON_VALUE(jsonContent, '$.year')  AS year
    JSON_VALUE(jsonContent, '$.population')  AS population
FROM  OPENROWSET(
        BULK 'https://XYZ.blob.core.windows.net/json/taxi/*.json', 
        FORMAT='CSV', 
        FIELDTERMINATOR ='0x0b',
        FIELDQUOTE = '0x0b', 
        ROWTERMINATOR = '0x0b'
    )
    WITH ( jsonContent varchar(MAX)   ) AS json_line