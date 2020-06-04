/*----------------------------------------------------------------------------- 
  Date       : 1 May 2010 
  SQL Version: SQL Server 2005/2008 
  Author     : Jacob Sebastian 
  Email      : jacob@beyondrelational.com 
  Twitter    : @jacobsebastian  
  Blog       : http://beyondrelational.com/blogs/jacob 
  Website    : http://beyondrelational.com

  Summary: 
  This script returns a tabular representation of an XML document

  Modification History:
  Jacob Sebastian - 1 May 2010
		Created the first version
  Jacob Sebatian - 18 June 2010
		Fixed a bug in the XPath Expressiong generated
  Jacob Sebastian - 20 June 2010
		Added new column - ParentName
		Updated the 'treeview' column to show lines
		Added new column - 'Position'
		Added New Column - 'ParentPosition'
  Jacob Sebastian - 23 June 2010		
		Made the function UNICODE compatibile. (Thanks Peso)
  Jacob Sebastian - 30 June 2010		
		Corrected the casing of a few columns to make the function
		work on case sensitive SQL Server installations. 
		(Thanks Rhodri Evans)               
		
  Notes:
  If you find this script useful, let us know by writing a comment at
  http://beyondrelational.com/blogs/jacob/archive/2010/05/30/select-from-xml.aspx
	
  Disclaimer:  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A 
  PARTICULAR PURPOSE. 
-----------------------------------------------------------------------------*/ 
/* 
SELECT * FROM dbo.XMLTable(' 
<employees> 
    <emp name="jacob"/> 
    <emp name="steve"> 
        <phone>123</phone> 
    </emp> 
</employees> 
') 
*/ 
CREATE FUNCTION [dbo].[XMLTable]( 
    @x XML 
) 
RETURNS TABLE 
AS RETURN 
/*---------------------------------------------------------------------- 
This INLINE TVF uses a recursive CTE that processes each element and 
attribute of the XML document passed in. 
----------------------------------------------------------------------*/ 
WITH cte AS ( 
    /*------------------------------------------------------------------ 
    Anchor part of the recursive query. Retrieves the root element 
    of the XML document 
    ------------------------------------------------------------------*/ 
    SELECT 
        1 AS lvl, 
        x.value('local-name(.)','NVARCHAR(MAX)') AS Name, 
        CAST(NULL AS NVARCHAR(MAX)) AS ParentName,
        CAST(1 AS INT) AS ParentPosition,
        CAST(N'Element' AS NVARCHAR(20)) AS NodeType, 
        x.value('local-name(.)','NVARCHAR(MAX)') AS FullPath, 
        x.value('local-name(.)','NVARCHAR(MAX)') 
            + N'[' 
            + CAST(ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS NVARCHAR) 
            + N']' AS XPath, 
        ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS Position,
        x.value('local-name(.)','NVARCHAR(MAX)') AS Tree, 
        x.value('text()[1]','NVARCHAR(MAX)') AS Value, 
        x.query('.') AS this,        
        x.query('*') AS t, 
        CAST(CAST(1 AS VARBINARY(4)) AS VARBINARY(MAX)) AS Sort, 
        CAST(1 AS INT) AS ID 
    FROM @x.nodes('/*') a(x) 
    UNION ALL 
    /*------------------------------------------------------------------ 
    Start recursion. Retrieve each child element of the parent node 
    ------------------------------------------------------------------*/ 
    SELECT 
        p.lvl + 1 AS lvl, 
        c.value('local-name(.)','NVARCHAR(MAX)') AS Name, 
        CAST(p.Name AS NVARCHAR(MAX)) AS ParentName,
        CAST(p.Position AS INT) AS ParentPosition,
        CAST(N'Element' AS NVARCHAR(20)) AS NodeType, 
        CAST( 
            p.FullPath 
            + N'/' 
            + c.value('local-name(.)','NVARCHAR(MAX)') AS NVARCHAR(MAX) 
        ) AS FullPath, 
        CAST( 
            p.XPath 
            + N'/' 
            + c.value('local-name(.)','NVARCHAR(MAX)') 
            + N'[' 
            + CAST(ROW_NUMBER() OVER(
				PARTITION BY c.value('local-name(.)','NVARCHAR(MAX)')
				ORDER BY (SELECT 1)) AS NVARCHAR	) 
            + N']' AS NVARCHAR(MAX) 
        ) AS XPath, 
        ROW_NUMBER() OVER(
				PARTITION BY c.value('local-name(.)','NVARCHAR(MAX)')
				ORDER BY (SELECT 1)) AS Position,
        CAST( 
            SPACE(2 * p.lvl - 1) + N'|' + REPLICATE(N'-', 1)
            + c.value('local-name(.)','NVARCHAR(MAX)') AS NVARCHAR(MAX) 
        ) AS Tree, 
        CAST( c.value('text()[1]','NVARCHAR(MAX)') AS NVARCHAR(MAX) ) AS Value, 
        c.query('.') AS this,        
        c.query('*') AS t, 
        CAST( 
            p.Sort 
            + CAST( (lvl + 1) * 1024 
            + (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) * 2) AS VARBINARY(4) 
        ) AS VARBINARY(MAX) ) AS Sort, 
        CAST( 
            (lvl + 1) * 1024 
            + (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) * 2) AS INT 
        ) 
    FROM cte p 
    CROSS APPLY p.t.nodes('*') b(c)        
), cte2 AS ( 
    SELECT 
        lvl AS Depth, 
        Name AS NodeName, 
        ParentName,
        ParentPosition,
        NodeType, 
        FullPath, 
        XPath, 
        Position,
        Tree AS TreeView, 
        Value, 
        this AS XMLData, 
        Sort, ID 
    FROM cte 
    UNION ALL 
    /*------------------------------------------------------------------ 
    Attributes do not need recursive calls. So add the attributes 
    to the query output at the end. 
    ------------------------------------------------------------------*/ 
    SELECT 
        p.lvl, 
        x.value('local-name(.)','NVARCHAR(MAX)'), 
        p.Name,
        p.Position,
        CAST(N'Attribute' AS NVARCHAR(20)), 
        p.FullPath + N'/@' + x.value('local-name(.)','NVARCHAR(MAX)'), 
        p.XPath + N'/@' + x.value('local-name(.)','NVARCHAR(MAX)'), 
        1,
        SPACE(2 * p.lvl - 1) + N'|' + REPLICATE('-', 1) 
			+ N'@' + x.value('local-name(.)','NVARCHAR(MAX)'), 
        x.value('.','NVARCHAR(MAX)'), 
        NULL, 
        p.Sort, 
        p.ID + 1 
    FROM cte p 
    CROSS APPLY this.nodes('/*/@*') a(x) 
) 
SELECT 
    ROW_NUMBER() OVER(ORDER BY Sort, ID) AS ID, 
    ParentName, ParentPosition,Depth, NodeName, Position,  
    NodeType, FullPath, XPath, TreeView, Value, XMLData
FROM cte2

