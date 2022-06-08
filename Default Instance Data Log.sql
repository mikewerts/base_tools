 /* get the backup directory */
 
 create table #backupdirectory(
 DataValue sql_variant,
 DataPath sql_variant
 )

 --declare @sqlquery as nvarchar(max)

 insert into #backupdirectory
 
 EXEC  master.dbo.xp_instance_regread 
 N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory'
 go

 /* get the root directory */

   declare @SQLDataRoot varchar(256)

 create table #rootdirectory(
 DataValue sql_variant,
 DataPath sql_variant
 )

insert into #rootdirectory 
exec master..xp_instance_regread
   @rootkey='HKEY_LOCAL_MACHINE',
   @key='SOFTWARE\Microsoft\MSSQLServer\Setup',
   @value_name='SQLDataRoot'

select 'Data Root Directory', DataPath
from #rootdirectory

 union all

 
SELECT
'User database directory', SERVERPROPERTY('InstanceDefaultDataPath') 

 

union all
select 
'User database log directory', SERVERPROPERTY('InstanceDefaultLogPath') 


/* SQL 2008R2 and earlier
CREATE TABLE #tempInstanceNames
(
	InstanceName	NVARCHAR(100),
	RegPath			NVARCHAR(100),
	DefaultDataPath	NVARCHAR(MAX)
)


/*	Extract all local instance names from registry;
	insert into temporary object
*/
INSERT INTO #tempInstanceNames (InstanceName, RegPath)
EXEC   master..xp_instance_regenumvalues
       @rootkey = N'HKEY_LOCAL_MACHINE',
       @key     = N'SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL'
       

/*	Now we have all local instance names, and their registry paths
*/
--SELECT	InstanceName, RegPath, DefaultDataPath
--FROM	#tempInstanceNames
       

/*	Need to query default data directory for each instance,
	The path is same for all instances, except the instance name part

	HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\<InstanceName>\MSSQLServer
	
	Registry Values:
	DefaultData		= Default Data Directory
	DefaultLog		= Default Log Directory
	BackupDirectory	= Default Backup Directory
*/
DECLARE     @SQL VARCHAR(MAX)
SET         @SQL = 'DECLARE @returnValue NVARCHAR(100)'
SELECT @SQL = @SQL + CHAR(13) +
'EXEC   master.dbo.xp_regread
@rootkey      = N''HKEY_LOCAL_MACHINE'',
@key          = N''SOFTWARE\Microsoft\Microsoft SQL Server\' + RegPath + '\MSSQLServer'',
@value_name   = N''DefaultData'', 
@value        = @returnValue OUTPUT;

UPDATE #tempInstanceNames SET DefaultDataPath = @returnValue
WHERE RegPath = ''' + RegPath + '''' + CHAR(13) FROM #tempInstanceNames


/*	Tip: To see what query is being generated, use
	PRINT (@SQL) instead of EXEC (@SQL)
*/
EXEC (@SQL)


/*	Default data paths should now be populated
*/
SELECT	InstanceName, RegPath, DefaultDataPath
FROM	#tempInstanceNames


/*	Clean up...
*/
DROP TABLE #tempInstanceNames


*/

union all

/* now get the temp data directory */
select top 1

'Temp DB Directory',  REVERSE(SUBSTRING(REVERSE(physical_name),CHARINDEX('\',REVERSE(physical_name)),len(physical_name)))  

from sys.master_files mf
 
 where type = 1

 and name like 'temp%'


 union all

 /* now get the temp log directory */
select top 1

'Temp DB log Directory',  REVERSE(SUBSTRING(REVERSE(physical_name),CHARINDEX('\',REVERSE(physical_name)),len(physical_name)))  

from sys.master_files mf 
 
 where type = 0

 and name like 'temp%'

 union all

 /* now get the default backup directory */



 select 'Backup Directory', DataPath 
 from #backupdirectory



 drop table #backupdirectory

 drop table #rootdirectory

