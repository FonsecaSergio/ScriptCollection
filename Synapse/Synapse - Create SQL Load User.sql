--MASTER
CREATE login loaduser with password = 'Microsoft@2021'

--USERDB
CREATE USER loaduser for login loaduser
EXEC sp_addrolemember 'largerc', 'loaduser';
EXEC sp_addrolemember 'db_owner', 'loaduser';

