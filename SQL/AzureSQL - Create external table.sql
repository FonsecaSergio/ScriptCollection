/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-04-06
************************************************/

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Microsoft@2020'

CREATE DATABASE SCOPED CREDENTIAL XPTO WITH IDENTITY = 'FonsecaSergio',SECRET = 'xxxxxx';

CREATE EXTERNAL DATA SOURCE Customer WITH
(TYPE = RDBMS,
LOCATION = 'fonsecanet.database.windows.net',
DATABASE_NAME = 'Test2',
CREDENTIAL = XPTO
) ;

CREATE EXTERNAL TABLE [dbo].[Customer](
	[CustomerID] [int] NOT NULL,
	[NameStyle] [dbo].[NameStyle] NOT NULL,
	[Title] [nvarchar](8) NULL,
	[FirstName] [dbo].[Name] NOT NULL,
	[MiddleName] [dbo].[Name] NULL,
	[LastName] [dbo].[Name] NOT NULL,
	[Suffix] [nvarchar](10) NULL,
	[CompanyName] [nvarchar](128) NULL,
	[SalesPerson] [nvarchar](256) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[Phone] [dbo].[Phone] NULL,
	[PasswordHash] [varchar](128) NOT NULL,
	[PasswordSalt] [varchar](10) NOT NULL,
	[rowguid] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
)
WITH
(
	DATA_SOURCE = Customer,
	SCHEMA_NAME = 'SalesLT',
	OBJECT_NAME = 'Customer',
);

SELECT TOP 1 * FROM [dbo].[Customer]