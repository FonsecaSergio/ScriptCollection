/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: 2020-08-14
************************************************/

---------------------------------------------
--DROP
	--In User DB
	DROP USER IF EXISTS [username]

	--In Master DB
	DROP LOGIN [login_name]
---------------------------------------------
--CREATE

	--In User DB
	CREATE USER [username]  
	WITH PASSWORD='P@ssw0rd'
	GO  
	
	--ALTER ROLE [db_owner]
	--	ADD MEMBER [username]

	ALTER ROLE [db_datareader]
		ADD MEMBER [username]
	GO
	ALTER ROLE [db_datawriter]
		ADD MEMBER [username]
	GO
	GRANT EXECUTE TO [username]

	--https://docs.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver15#_permissions





