------------------------------------------------------------------------------------------------------
--READ DATA FROM XML VAR
------------------------------------------------------------------------------------------------------

DECLARE @XML as XML

SET @XML =
'
<GROUPS> 
	<GROUP PRODUTO="RiscoCredito" MODALIDADE="ImpMultas" /> 
	<GROUP PRODUTO="VLRSCREDIALIB" MODALIDADE="Normal" /> 
</GROUPS>
'

IF OBJECT_ID('TEMPDB..#TEMP_GROUPS') IS NOT NULL
	DROP TABLE #TEMP_GROUPS


SELECT [PRODUTO]    = T.Item.value('@PRODUTO[1]'	 , 'varchar(50)'),
       [MODALIDADE] = T.Item.value('@MODALIDADE[1]' , 'varchar(50)')
INTO #TEMP_GROUPS
FROM   @XML.nodes('/GROUPS/GROUP') AS T(Item)

SELECT * FROM #TEMP_GROUPS


GO
------------------------------------------------------------------------------------------------------

DECLARE @XML as XML

SET @XML =
'
<GROUPS> 
	<GROUP> 
		<PRODUTO>RiscoCredito</PRODUTO>
		<MODALIDADE>ImpMultas</MODALIDADE>
	</GROUP>
	<GROUP> 
		<PRODUTO>VLRSCREDIALIB</PRODUTO>
		<MODALIDADE>Normal</MODALIDADE>
	</GROUP>
</GROUPS>
'

IF OBJECT_ID('TEMPDB..#TEMP_GROUPS') IS NOT NULL
	DROP TABLE #TEMP_GROUPS


SELECT [PRODUTO]    = T.Item.value('PRODUTO[1]'	 , 'varchar(50)'),
       [MODALIDADE] = T.Item.value('MODALIDADE[1]' , 'varchar(50)')
INTO #TEMP_GROUPS
FROM   @XML.nodes('/GROUPS/GROUP') AS T(Item)

SELECT * FROM #TEMP_GROUPS



GO
------------------------------------------------------------------------------------------------------

DECLARE @xml XML = 
'<root>
	<XPTO>1</XPTO>
	<XPTO>2</XPTO>
</root>'

select @xml

SELECT 
	X.Item.value('.','int')
FROM @xml.nodes('/root/XPTO') as X(Item)
