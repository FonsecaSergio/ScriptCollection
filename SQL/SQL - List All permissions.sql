/*
This script list all DB permissions

RUN ON USER DATABASE
*/

SET NOCOUNT ON
----------------------------------------------------------------------------------------------------------------
SELECT  'DB CONFIG'
SELECT * FROM sys.databases

----------------------------------------------------------------------------------------------------------------
SELECT  'DB USERS'

SELECT principal_id, name, type, type_desc, sid, authentication_type, authentication_type_desc
FROM sys.database_principals
WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas

----------------------------------------------------------------------------------------------------------------
SELECT 'DB ROLE MEMBERSHIP'
SELECT 
         [Role] = USER_NAME(rm.role_principal_id)
        ,[Membername] = USER_NAME(rm.member_principal_id)
FROM sys.database_role_members AS rm
WHERE USER_NAME(rm.member_principal_id) IN ( 
        --get user names on the database
        SELECT [name]
        FROM sys.database_principals
        WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
)
----------------------------------------------------------------------------------------------------------------
SELECT 'DB LEVEL PERMISSIONS'
SELECT 
         USERNAME = USER_NAME(usr.principal_id)
        ,perm.state
        ,perm.state_desc
        ,perm.permission_name
        ,perm.class
        ,perm.class_desc
        ,perm.major_id
        ,CASE
                WHEN perm.major_id = 0 then DB_NAME()
                WHEN perm.major_id > 1 then obj.name
                else NULL
        END
FROM sys.database_permissions AS perm
INNER JOIN sys.database_principals AS usr
        ON perm.grantee_principal_id = usr.principal_id
LEFT JOIN sys.objects obj
        ON perm.major_id = obj.object_id
