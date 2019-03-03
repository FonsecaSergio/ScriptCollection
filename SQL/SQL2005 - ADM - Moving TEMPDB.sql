--Moving Tempdb
--In order to move the tempdb database, open query analyzer and run the following query: 

use master
go
Alter database tempdb modify file (name = tempdev, filename = 'E:\Sqldata\tempdb.mdf')
go
Alter database tempdb modify file (name = templog, filename = 'E:\Sqldata\templog.ldf')
Go

