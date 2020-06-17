/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

SET NOCOUNT ON
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Limpa Objetos
----------------------------------------------------------------------------------------------------------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TABELA_PARTICIONADA]') AND type in (N'U'))
DROP TABLE [dbo].[TABELA_PARTICIONADA]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TABELA_INCLUSAO]') AND type in (N'U'))
DROP TABLE [dbo].[TABELA_INCLUSAO]
GO
IF  EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'TesteScheme')
DROP PARTITION SCHEME [TesteScheme]
GO
IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'TestePFN')
DROP PARTITION FUNCTION [TestePFN]
GO
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cria fun��o e schema da parti��o
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PARTITION FUNCTION [TestePFN](smallint) 
AS 
		RANGE LEFT FOR VALUES (-32000)
GO

CREATE PARTITION SCHEME [TesteScheme] 
	AS PARTITION [TestePFN] ALL TO ([PRIMARY])

----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cria tabela particionada
----------------------------------------------------------------------------------------------------------------------------------------------------------
GO
CREATE TABLE [TABELA_PARTICIONADA]
(
	ID SMALLINT NOT NULL PRIMARY KEY,
	TESTE INT,
	TESTE2 INT
) ON [TesteScheme] (ID)

INSERT INTO TABELA_PARTICIONADA
VALUES (-32000,1,1)
INSERT INTO TABELA_PARTICIONADA
VALUES (-31999,2,2)

----------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT VERIFICA REGISTROS DA TABELA_PARTICIONADA
----------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT '*********************************************'
PRINT 'DADOS INICIAIS'
PRINT '*********************************************'

SELECT $partition.[TestePFN](ID) as PARTICAO, * 
FROM TABELA_PARTICIONADA

----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cria tabela que ser� usada pelo SSIS - TESTE1
----------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT CHAR(10)+CHAR(10)+CHAR(10)
PRINT '*********************************************'
PRINT 'DADOS TESTE 1'
PRINT '*********************************************'

CREATE TABLE [TABELA_INCLUSAO]
(
	ID SMALLINT NOT NULL/* PRIMARY KEY*/,
	TESTE INT,
	TESTE2 INT
) ON [PRIMARY] --[TesteScheme] (ID)

INSERT INTO [TABELA_INCLUSAO]
VALUES (-31998,3,3)

ALTER TABLE dbo.TABELA_INCLUSAO 
	ADD CONSTRAINT PK_TABELA_INCLUSAO PRIMARY KEY CLUSTERED (ID) ON [PRIMARY]

ALTER TABLE dbo.TABELA_INCLUSAO 
	ADD CONSTRAINT CK_TABELA_INCLUSAO_ID CHECK (ID = -31998)

SELECT * FROM [TABELA_INCLUSAO]

----------------------------------------------------------------------------------------------------------------------------------------------------------
--Pega registros da tabela [TABELA_INCLUSAO] e joga na parti��o - TESTE1
--REALIZANDO UM SPLIT NA FUN��O
----------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER PARTITION SCHEME [TesteScheme]
NEXT USED [PRIMARY]

ALTER PARTITION FUNCTION [TestePFN] ()
	SPLIT RANGE(-31999)

DECLARE @PARTITION AS INT
SELECT @PARTITION = fanout FROM sys.partition_functions WHERE NAME = 'TestePFN'
--SELECT @PARTITION as [@PARTITION]


ALTER TABLE [TABELA_INCLUSAO]
	SWITCH TO [TABELA_PARTICIONADA] PARTITION @PARTITION

----------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT VERIFICA REGISTROS DA TABELA_PARTICIONADA - TESTE 1
----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT $partition.[TestePFN](ID) as PARTICAO, * 
FROM TABELA_PARTICIONADA

----------------------------------------------------------------------------------------------------------------------------------------------------------
--Cria tabela que ser� usada pelo SSIS - TESTE 2
----------------------------------------------------------------------------------------------------------------------------------------------------------
PRINT CHAR(10)+CHAR(10)+CHAR(10)
PRINT '*********************************************'
PRINT 'DADOS TESTE 2'
PRINT '*********************************************'

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TABELA_INCLUSAO]') AND type in (N'U'))
DROP TABLE [dbo].[TABELA_INCLUSAO]
GO
CREATE TABLE [TABELA_INCLUSAO]
(
	ID SMALLINT NOT NULL/* PRIMARY KEY*/,
	TESTE INT,
	TESTE2 INT
) ON [PRIMARY] --[TesteScheme] (ID)

INSERT INTO [TABELA_INCLUSAO]
VALUES (-31997,4,4)

ALTER TABLE dbo.TABELA_INCLUSAO 
	ADD CONSTRAINT PK_TABELA_INCLUSAO PRIMARY KEY CLUSTERED (ID) ON [PRIMARY]

ALTER TABLE dbo.TABELA_INCLUSAO 
	ADD CONSTRAINT CK_TABELA_INCLUSAO_ID CHECK (ID >= -31997)

SELECT * FROM [TABELA_INCLUSAO]


----------------------------------------------------------------------------------------------------------------------------------------------------------
--Pega registros da tabela [TABELA_INCLUSAO] e joga na parti��o - TESTE 2
--REALIZANDO UM SPLIT NA FUN��O
----------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER PARTITION SCHEME [TesteScheme]
NEXT USED [PRIMARY]

ALTER PARTITION FUNCTION [TestePFN] ()
	SPLIT RANGE(-31998)


DECLARE @PARTITION AS INT
SELECT @PARTITION = fanout FROM sys.partition_functions WHERE NAME = 'TestePFN'
--SELECT @PARTITION as [@PARTITION]

ALTER TABLE [TABELA_INCLUSAO]
	SWITCH TO [TABELA_PARTICIONADA] PARTITION @PARTITION

----------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT VERIFICA REGISTROS DA TABELA_PARTICIONADA
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT $partition.[TestePFN](ID) as PARTICAO, * 
FROM TABELA_PARTICIONADA

----------------------------------------------------------------------------------------------------------------------------------------------------------




PRINT CHAR(10)+CHAR(10)+CHAR(10)
PRINT '*********************************************'
PRINT 'DADOS TESTE 3 - REMOVENDO PARTI��O'
PRINT '*********************************************'
----------------------------------------------------------------------------------------------------------------------------------------------------------
--TESTE PARA TIRAR REGISTROS DA [TABELA_PARTICIONADA]
----------------------------------------------------------------------------------------------------------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TABELA_INCLUSAO]') AND type in (N'U'))
DROP TABLE [dbo].[TABELA_INCLUSAO]
GO
CREATE TABLE [TABELA_INCLUSAO]
(
	ID SMALLINT NOT NULL/* PRIMARY KEY*/,
	TESTE INT,
	TESTE2 INT
) ON [PRIMARY] --[TesteScheme] (ID)

ALTER TABLE dbo.TABELA_INCLUSAO 
	ADD CONSTRAINT PK_TABELA_INCLUSAO PRIMARY KEY CLUSTERED (ID) ON [PRIMARY]

SELECT * FROM [TABELA_INCLUSAO]

--TESTE TIRAR PARTICAODECLARE @PARTITION AS INT
DECLARE @PARTITION AS INT
SELECT @PARTITION = fanout FROM sys.partition_functions WHERE NAME = 'TestePFN'
--SELECT @PARTITION as [@PARTITION]

ALTER TABLE [TABELA_PARTICIONADA]
	SWITCH PARTITION @PARTITION TO [TABELA_INCLUSAO]

ALTER PARTITION FUNCTION [TestePFN] ()
	MERGE RANGE(-31998)
----------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT VERIFICA REGISTROS DA TABELA_PARTICIONADA
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT $partition.[TestePFN](ID) as PARTICAO, * 
FROM TABELA_PARTICIONADA

SELECT * FROM [TABELA_INCLUSAO]




SET NOCOUNT OFF









/*
SELECT $partition.[TestePFN](-32000)
SELECT $partition.[TestePFN](-31997)
SELECT $partition.[TestePFN](-31996)
SELECT $partition.[TestePFN](-31995)


SELECT * FROM sys.partition_range_values
SELECT * FROM sys.partition_functions
SELECT * FROM sys.partition_schemes
SELECT * FROM sys.partition_parameters
SELECT OBJECT_NAME(Object_ID),* FROM sys.partitions
*/