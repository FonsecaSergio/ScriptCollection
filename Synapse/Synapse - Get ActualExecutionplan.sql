/************************************************
Author: ??? / Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2022-01-27
************************************************/

--1 - Using a text editor add the following content to a new file:

declare @query nvarchar(max) = N'paste_your_query_here'
dbcc getqueryinfo(@query)

--2 - Save this file as etq2info.sql in your local desktop

--3 - Use the sqlcmd utility and run the following command from the location where you saved the previous file

sqlcmd -S yourservername.database.windows.net -U username -P password -I -d DwPerformanceTest -i .\getq2info.sql -o .\q2info.txt -y0
