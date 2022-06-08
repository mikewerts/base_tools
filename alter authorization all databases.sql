use [Beacon];
GO
use [master];
GO
USE [Beacon]
GO
ALTER AUTHORIZATION ON DATABASE::[Beacon] TO [MEMIC1\svc_beacnsql]
GO

select suser_sname(owner_sid) from sys.databases

declare @sql nvarchar(max)

set @sql = 'Use [?] 
IF DB_ID(''?'') > 4
ALTER AUTHORIZATION ON DATABASE::[?] TO [MEMIC1\svc_beacnsql]'





exec sp_MSforeachdb @sql
