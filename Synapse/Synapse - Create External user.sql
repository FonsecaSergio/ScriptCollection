
--DROP USER [sefonsec_SQLAdmin]
--CREATE USER [sefonsec_SQLAdmin] FROM EXTERNAL PROVIDER

select cast(cast('<Object Id>' as uniqueidentifier) as varbinary(16)) SID;
select cast(cast('1b6b4f9c-719f-4034-84ff-606fdda81e5a' as uniqueidentifier) as varbinary(16)) SID;
--0x9C4F6B1B9F71344084FF606FDDA81E5A

Create user [USERNAME] with sid = [SID], type = E--EXTERNAL USER
Create user [GROUPNAME] with sid = [SID], type = X--EXTERNAL GROUP

Create user [sefonsec@microsoft] with sid = 0x9C4F6B1B9F71344084FF606FDDA81E5A, type = E --EXTERNAL USER
Create user [sefonsec_SQLAdmin] with sid = 0x9C4F6B1B9F71344084FF606FDDA81E5A, type = X --EXTERNAL GROUP

SELECT * FROM sys.database_principals

