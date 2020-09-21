/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-09-09
************************************************/

--CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrongPassword1';
GO

DROP EXTERNAL DATA SOURCE MyAzureBlobStorage
DROP DATABASE SCOPED CREDENTIAL msi_cred;
GO

CREATE DATABASE SCOPED CREDENTIAL msi_cred WITH IDENTITY = 'Managed Identity';-- DO NOT CHANGE IT. Use 'Managed Identity'
GO

CREATE EXTERNAL DATA SOURCE MyAzureBlobStorage
WITH ( TYPE = BLOB_STORAGE,
	 LOCATION = 'https://fonsecanetstorage.blob.core.windows.net/csv'
	,CREDENTIAL= msi_cred
);
GO
                 

SELECT * FROM OPENROWSET(
	BULK 'CSVSAMPLE.CSV',
	DATA_SOURCE = 'MyAzureBlobStorage',
	SINGLE_CLOB) AS DataFile;

GO
TRUNCATE TABLE TestImportCSV
GO
BULK INSERT TestImportCSV
FROM 'CSVSAMPLE.CSV'
WITH (
	DATA_SOURCE = 'MyAzureBlobStorage',
	FORMAT = 'CSV',
	FIRSTROW=2
	);
GO
SELECT * FROM TestImportCSV