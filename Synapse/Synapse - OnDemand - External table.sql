/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-10-28
************************************************
--https://azure.microsoft.com/en-us/services/open-datasets/catalog/ecdc-covid-19-cases/
************************************************/

IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat') 
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat] 
	WITH ( FORMAT_TYPE = PARQUET)
GO

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'fonsecanet_fonsecanetdatalake_dfs_core_windows_net') 
	CREATE EXTERNAL DATA SOURCE [fonsecanet_fonsecanetdatalake_dfs_core_windows_net] 
	WITH (
		LOCATION   = 'https://fonsecanetdatalake.dfs.core.windows.net/fonsecanet', 
	)
Go

CREATE EXTERNAL TABLE dbo.covid (
	[date_rep] date,
	[day] smallint,
	[month] smallint,
	[year] smallint,
	[cases] smallint,
	[deaths] smallint,
	[countries_and_territories] varchar(8000),
	[geo_id] varchar(8000),
	[country_territory_code] varchar(8000),
	[pop_data_2018] int,
	[continent_exp] varchar(8000),
	[load_date] datetime2(7),
	[iso_country] varchar(8000)
	)
	WITH (
	LOCATION = 'Parquet/20201026_ecdc_cases.parquet',
	DATA_SOURCE = [fonsecanet_fonsecanetdatalake_dfs_core_windows_net],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO

SELECT TOP 100 * FROM dbo.covid WHERE geo_id = 'pt'
GO

