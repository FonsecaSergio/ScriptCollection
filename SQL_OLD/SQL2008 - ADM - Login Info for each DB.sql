create table #UsrDataMapping(
[database_name] [sysname] NULL,
[name] [sysname] NULL,
[schema] [sysname] NULL
)
EXEC sp_MSforeachdb 'insert into #UsrDataMapping SELECT ''?'' as DBNAME,
--u.name AS [Name],
SUSER_SNAME(sid) AS [Name],
ISNULL(u.default_schema_name,N'''') AS [DefaultSchema]
FROM
[?].sys.database_principals AS u
LEFT OUTER JOIN [?].sys.database_permissions AS dp ON dp.grantee_principal_id = u.principal_id 
WHERE
(u.type in (''U'', ''S'', ''G'', ''C'', ''K''))
and dp.state = ''G''
'
select * from #UsrDataMapping order by database_name
drop table #UsrDataMapping 