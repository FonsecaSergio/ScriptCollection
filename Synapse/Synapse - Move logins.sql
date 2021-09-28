--REF: https://docs.microsoft.com/en-us/sql/sql-server/failover-clusters/troubleshoot-orphaned-users-sql-server?view=sql-server-ver15

--SOURCE
	--master
	--Get Sid + name
	SELECT sid,name,password_hash
	FROM sys.sql_logins 
	WHERE type = 'S'-- SQL_Login

-- Destination
	--master
	CREATE LOGIN <login_name>   
	WITH PASSWORD = '<use_a_strong_password_here>',  
	SID = <SID>;

	--userdb
	-- Check if user maps to login SID
		SELECT name, sid, principal_id
		FROM sys.database_principals 
		WHERE type = 'S' 
		  AND name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys')
		  AND authentication_type_desc = 'INSTANCE';

    --If login exists and SID does not match Map to existing user
	ALTER USER <user_name> WITH Login = <login_name>;

--Cannot add login with hashed password
--	Msg 40517, Level 16, State 1, Line 32
--	Keyword or statement option 'hashed' is not supported in this version of SQL Server.