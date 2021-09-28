/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-10-23
************************************************
-- COVID DATA ANALYSIS
--https://techcommunity.microsoft.com/t5/azure-synapse-analytics/how-azure-synapse-analytics-helps-you-analyze-covid-data-with/ba-p/1457836
--https://techcommunity.microsoft.com/t5/azure-synapse-analytics/create-external-tables-to-analyze-covid-data-set-using-azure/ba-p/1592711
--https://azure.microsoft.com/en-us/services/open-datasets/catalog/ecdc-covid-19-cases/
************************************************/

select top 10  *
from openrowset(bulk 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
                format='parquet') as a

select countries_and_territories, geo_id
from openrowset(bulk 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
                format='parquet') as a
where countries_and_territories like '%Portugal%'

select GEO_ID, DATE_REP, CASES, DEATHS
from openrowset(bulk 'https://pandemicdatalake.blob.core.windows.net/public/curated/covid-19/ecdc_cases/latest/ecdc_cases.parquet',
                format='parquet') as a
where GEO_ID = 'PT'
order by DATE_REP