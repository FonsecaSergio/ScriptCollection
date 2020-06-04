#https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-linux-ver15#pullandrun2019

#NEEED TO UPDATE FROM LAST VERSION
#https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver15&pivots=cs1-powershell


################################################
#Pull and run the container image
docker pull mcr.microsoft.com/mssql/server:2019-CTP2.1-ubuntu


docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=xxxxxx" `
   -p 1433:1433 --name sql2019 `
   -d mcr.microsoft.com/mssql/server:2019-CTP2.1-ubuntu

################################################
#view your Docker containers
docker ps -a

################################################
#ErrorLog
$ERRORLOG = docker logs sql2019
$ERRORLOG

################################################
#SQL Server command-line tool, sqlcmd
#Use Container ID
docker exec -it sql2019 /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'xxxxxx'

docker exec -it sql2019 /opt/mssql-tools/bin/sqlcmd `
   -S localhost -U SA -P "xxxxxx" `
   -Q "SELECT @@VERSION"

docker exec -it sql2019 /opt/mssql-tools/bin/sqlcmd `
   -S localhost -U SA -P "xxxxxx" `
   -Q "ALTER LOGIN SA WITH PASSWORD='xxxxxx'"


################################################
#GET IP
$DockerIPRange = "10.0.75.*"
Get-NetIPAddress | Where-Object {$_.IPAddress -like $DockerIPRange} | Select IPAddress



################################################
SELECT
    @@version, 
    @@SERVERNAME,
    SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),
    SERVERPROPERTY('MachineName'),
    SERVERPROPERTY('ServerName')
GO

CREATE DATABASE TEST
GO

USE test

CREATE TABLE TEST (id int, name varchar(50))
GO
INSERT INTO TEST (id,name) VALUES(1,1),(2,2)
GO
SELECT * FROM TEST

################################################
#STOP
docker stop sql2019

################################################
#START
docker start sql2019

################################################
#REMOVE
docker stop sql2019
docker rm sql2019

################################################

docker ps -a
