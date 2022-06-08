select  s.name as databasename, m.name as filename, m.physical_name as physical_file_name, (size * 8 / 1024.0 /1024.0) as 'size GB' ,s.recovery_model_desc
--, (max_size * 8 / 1024.0 /1024.0) as 'max size GB'

 from sys.master_files m

join sys.databases s
on s.database_id = m.database_id
where type = 1 
/* MJW 7-14-21 exclude DB mounts on Rubrik */

and SUBSTRING(m.physical_name, 1, 1) <> '\'

--or 
-- s.name like 'temp%'

order by (size * 8 / 1024.0 /1024.0) desc, s.name  

  /* Get volume information for everything but tempdb */

select volume_mount_point, shortcut, sum(DB_Size) as total_database_size_MB, volume_id, total_MB, available_MB  from 

(
SELECT --DISTINCT
    SUBSTRING(volume_mount_point, 1, 1) AS volume_mount_point,
	/* return the partition name when it exists otherwise drive letter*/
	CASE WHEN LEN(volume_mount_point) > 3
	then
	SUBSTRING(volume_mount_point, 4, len(volume_mount_point) - 4) 
	else 
	volume_mount_point 
	END AS shortcut,
	volume_id,
	size/1024*8 as DB_Size,
	    total_bytes/1024/1024 AS total_MB
    ,available_bytes/1024/1024 AS available_MB
	from sys.master_files f
	/* temp db reflected inaccurately */
	

CROSS APPLY
    sys.dm_os_volume_stats(f.database_id, f.file_id)
	where name not like 'temp%'
) d
/* MJW 7-14-21 exclude DB mounts on Rubrik */

where SUBSTRING(volume_mount_point, 1, 1) <> '\'

group by volume_mount_point, shortcut, volume_id, total_MB, available_MB


use tempdb

select  'Temp DB', m.name as filename, m.physical_name as physical_file_name, (size * 8 / 1024.0 /1024.0) as 'size GB'
, (max_size * 8 / 1024.0 /1024.0) as 'max size GB' from sys.database_files m
join sys.sysdatabases s
on s.dbid = m.file_id
--where m.name = 'tempdev'

/* now check the available volume size */

select volume_mount_point, shortcut, sum(DB_Size) as total_database_size_MB, volume_id, total_MB, available_MB  from 

(
select  
SUBSTRING(volume_mount_point, 1, 1) AS volume_mount_point,
	/* return the partition name when it exists otherwise drive letter*/
	CASE WHEN LEN(volume_mount_point) > 3
	then
	SUBSTRING(volume_mount_point, 4, len(volume_mount_point) - 4) 
	else 
	volume_mount_point 
	END AS shortcut,
	volume_id,

--	m.name as filename, --m.physical_name as physical_file_name
 (size * 8 / 1024 ) as DB_Size,
 	    total_bytes/1024/1024 AS total_MB
    ,available_bytes/1024/1024 AS available_MB
--,case when max_size < 0 then cast('Unlimited' as nvarchar) 
--else 
--(max_size * 8 / 1024 ) as 'max size MB' 
--use tempdb
--select * 

from sys.database_files m
--join sys.sysdatabases s
--on s.file_id = m.file_id
CROSS APPLY
    sys.dm_os_volume_stats((select database_id from sys.databases m where name like 'tempdb%'), m.file_id)
) e

group by volume_mount_point, shortcut, volume_id, total_MB, available_MB

/* check the wait status on all databases */

SELECT name, log_reuse_wait_desc FROM sys.databases;

--DBCC SQLPERF(LOGSPACE);

--In my case, this showed two databases with log files > 65GB.

--2. Next, backup the Log file to free up space within the file (logically/virtually). Ideally, if you had enough disk space, you would backup the log file to an actual file somewhere. Otherwise, if you are okay with an RPO of 24 hours (to your last full backup) then you can backup to a null device (great blog article here describing this method, please heed the disclaimers).

--BACKUP LOG <logname> TO DISK='NUL:'

/*
Note: Technically you should be able to run this command against the primary replica or the secondary replica, and the log file will be truncated in both places according to this blog article.

--3. Next, verify if the log file is in a state that will allow shrinking. If your status is ‘2’ then you will need to proceed to step 4, otherwise if the Status is ‘0’ (Zero) then you can skip to step 5.

*/

/* View space that can be freed after active log SQL Server 2016 above */

declare @majorversion int
set @majorversion = (select cast(SERVERPROPERTY('ProductMajorVersion') as int))
print @majorversion

if @majorversion > 12
begin

if object_id('tempdb..##freeloginfotable') is not null drop table ##freeloginfotable
create table ##freeloginfotable
(
/*
RecoveryUnitId	int,
FileId	smallint,
FileSize	bigint,
StartOffset	float,
FSeqNo	bigint,
Status	int,
Parity	tinyint,
CreateLSN nvarchar(48)
*/
[Database Name] nvarchar(max),
free_mb_after_active_log decimal(9,2),
vlf_count int, 
min_vlf_active int, 
ordinal_min_vlf_active int,
max_vlf_active int,
ordinal_max_vlf_active int,
free_log_pct_before_active_log decimal(9,4),
active_log_pct decimal(9,4),
free_log_pct_after_active_log decimal(9,4)
)
declare @sql nvarchar(max)
set @sql = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') 
/* exclude Rubrik mount point databases */
and ''?''  IN(
select  s.name as databasename
 from sys.master_files m
join sys.databases s
on s.database_id = m.database_id
where type = 1 
and SUBSTRING(m.physical_name, 1, 1) <> ''\''
)

/* mjw 7/20/21 */
BEGIN USE [?]

declare @datbasename nvarchar(48);
set @datbasename = ''[?]''



;WITH cte_vlf AS (
SELECT ROW_NUMBER() OVER(ORDER BY vlf_begin_offset) AS vlfid, DB_NAME(database_id) AS [Database Name], vlf_sequence_number, vlf_active, vlf_begin_offset, vlf_size_mb
	FROM sys.dm_db_log_info(DEFAULT)),
cte_vlf_cnt AS (SELECT [Database Name], COUNT(vlf_sequence_number) AS vlf_count,
	(SELECT COUNT(vlf_sequence_number) FROM cte_vlf WHERE vlf_active = 0) AS vlf_count_inactive,
	(SELECT COUNT(vlf_sequence_number) FROM cte_vlf WHERE vlf_active = 1) AS vlf_count_active,
	(SELECT MIN(vlfid) FROM cte_vlf WHERE vlf_active = 1) AS ordinal_min_vlf_active,
	(SELECT MIN(vlf_sequence_number) FROM cte_vlf WHERE vlf_active = 1) AS min_vlf_active,
	(SELECT MAX(vlfid) FROM cte_vlf WHERE vlf_active = 1) AS ordinal_max_vlf_active,
	(SELECT MAX(vlf_sequence_number) FROM cte_vlf WHERE vlf_active = 1) AS max_vlf_active,
	sum(vlf_size_mb) as size_mb
	FROM cte_vlf
	GROUP BY [Database Name])


insert into ##freeloginfotable SELECT @datbasename, 

convert(numeric(9,2),(cast (vlf_count as decimal(9,2)) -  cast (ordinal_max_vlf_active as decimal(9,2)))/cast (vlf_count as decimal(9,2)) * cast( size_mb as decimal (9,2))) 
as free_mb_after_active_log,
vlf_count, ordinal_max_vlf_active, min_vlf_active, ordinal_min_vlf_active, max_vlf_active, 
((ordinal_min_vlf_active-1)*100.00/vlf_count) AS free_log_pct_before_active_log,

((ordinal_max_vlf_active-(ordinal_min_vlf_active-1))*100.00/vlf_count) AS active_log_pct,
((vlf_count-ordinal_max_vlf_active)*100.00/vlf_count) AS free_log_pct_after_active_log

FROM cte_vlf_cnt
END
'



exec sp_msforEachDB @sql

select * from ##freeloginfotable order by free_mb_after_active_log desc 

end

/* View all databases VLFs */


declare @sql2 nvarchar(max)
set @sql2 = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') 
/* exclude Rubrik mount point databases */
and ''?''  IN(
select  s.name as databasename
 from sys.master_files m
join sys.databases s
on s.database_id = m.database_id
where type = 1 
and SUBSTRING(m.physical_name, 1, 1) <> ''\''
)
/* mjw 7/20/21 */
BEGIN USE [?]


--dbcc loginfo

declare @datbasename nvarchar(48);
set @datbasename = ''[?]''

declare @loginfotable table
(

RecoveryUnitId	int,
FileId	smallint,
FileSize	bigint,
StartOffset	float,
FSeqNo	bigint,
Status	int,
Parity	tinyint,
CreateLSN nvarchar(48)
)

insert into @loginfotable exec(''dbcc loginfo'')

select --top 1 
@datbasename ''Database'', l.* from @loginfotable l
--where l.status = 2
END
'


exec sp_msforEachDB @sql2



--Use UnderwritingReporting --_log -- _Log
--GO
--dbcc loginfo
--Use UnderwritingReporting
--declare @datbasename nvarchar(48);
--declare @allloginfotable table
--(
--databasename nvarchar(max),
--RecoveryUnitId	int,
--FileId	smallint,
--FileSize	bigint,
--StartOffset	float,
--FSeqNo	bigint,
--Status	int,
--Parity	tinyint,
--CreateLSN nvarchar(48)
--)

--set @datbasename = 'UnderwritingReporting';


--declare @loginfotable table



--(
----databasename nvarchar
--RecoveryUnitId	int,
--FileId	smallint,
--FileSize	bigint,
--StartOffset	float,
--FSeqNo	bigint,
--Status	int,
--Parity	tinyint,
--CreateLSN nvarchar(48)
--)

--insert into @loginfotable exec('dbcc loginfo')

--insert into @allloginfotable select top 1 @datbasename, l.* from @loginfotable l
--where l.status = 2

--select * from @allloginfotable




/*
4. This step will reset the log file so that you can physically shrink it in step 5. Again, this step assumes that you are okay with a 24 hour RPO as you will only be able to restore to your last full backup.  I’ve worked with enough DBA’s that if I don’t add these disclaimers at each step then they will certainly spam the comments with ‘don’t ever do this step’ =)
*/
--DBCC SHRINKFILE (ClaimServiceSummary_log, EMPTYFILE);

/* Next, re-run step 3 (dbcc loginfo) and verify that Status is now 0 instead of 2. If it is, then proceed to step 5, otherwise re-run step 2 and 4.

--5. Now that the transaction log has been backed up, and emptied, it is now possible to physically shrink the size of the log file on disk with this command:

*/

--use DEV_CLAIMSXPRESS
--go
--DBCC shrinkfile (Sims09R2_log, 16)


/* 

6. If the tempdb has gotten extremely large, run the following:


*/

--use tempdb
--go
--DBCC shrinkfile (tempdev, 16);   --This would physically shrink the database size to 500 Megabytes.

/*

7. If you can't shrink the tempdb, try using FREEPROCCACHE:

*/


--use tempdb
--go
--DBCC FREESYSTEMCACHE ('ALL')

--DBCC shrinkfile (tempdev, 16);  


/*
8. As a last resort, use FREESYSTEMCACHE ('ALL')

*/

--DBCC FREESYSTEMCACHE ('ALL')

/*
Important: you can only shrink files against the primary replica. The good news is that once you shrink the primary, the physical size of the secondary replicas will shrink too, so you only need to do this in one place.

Hint: dbcc opentran shows if there are open transactions that could block the shrink operation.

Hint #2: If the log files still will not shrink, check to make sure that the secondary replica database is not marked as Suspect. In that case, you will need to manually remove the suspect database from the secondary first before the shrink operation will work.

Note: Before determining the size of 500Mb to shrink to, you may want to consider how much of the log file is in use, otherwise the shrink operation will not work. Also, you may want to consider allowing the size of the log file to be 25% of the size of the physical database file (.MDF) because otherwise when log growth happens, the database operations will block all active transactions and that will cause latency within applications (imagine users complaining).

You can determine how much of the log file is in use by running this query:

*/

--Use MEMIC_CRM_Integration
--GO

--SELECT name, size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
--FROM sys.database_files;


/* 9. Move databases from one drive to another */

/* data file */
--ALTER DATABASE ProfitSharing MODIFY FILE ( NAME = ProfitSharing , FILENAME = 'E:\Program Files\Microsoft SQL Server\MSSQL11.VINYLQA\MSSQL\Data\ProfitSharing.mdf' )
/* log file */
--ALTER DATABASE ProfitSharing MODIFY FILE ( NAME = ProfitSharing_log , FILENAME = 'E:\Program Files\Microsoft SQL Server\MSSQL11.VINYLQA\MSSQL\Data\ProfitSharing_log.ldf' )



/*
USE [master]
GO
ALTER DATABASE [MEMIC_SOURCE] SET RECOVERY SIMPLE WITH NO_WAIT
GO

USE [master]
GO
ALTER DATABASE [MEMIC_SOURCE] SET RECOVERY FULL WITH NO_WAIT
GO

*/

