CREATE TABLE XmlImportTest
(
    xmlFileName VARCHAR(300),
    xml_data xml
)
GO

DECLARE @xmlFileName VARCHAR(MAX)
SELECT  @xmlFileName = 'D:\TEMP\TEMPORÁRIO MESMO\BANCOS.XML'
-- dynamic sql is just so we can use @xmlFileName variable in OPENROWSET
EXEC('
INSERT INTO XmlImportTest(xmlFileName, xml_data)

SELECT ''' + @xmlFileName + ''', xmlData 
FROM
(
    SELECT  * 
    FROM    OPENROWSET (BULK ''' + @xmlFileName + ''' , SINGLE_BLOB) AS XMLDATA
) AS FileImport (XMLDATA)
')
GO
SELECT * FROM XmlImportTest

DROP TABLE XmlImportTest