/* added CTE to get most recent restore and most recent backup for each database */
drop table #most_recent_restore

create table #most_recent_restore
(
DestDBName nvarchar(128),
restore_date datetime,
restore_type char(1),
user_name nvarchar(128),
server_name	nvarchar(128),
database_name nvarchar(128),
backup_finish_date datetime,
backup_set_id int,
)

go



with most_recent_restore
as
(

SELECT
max(restorehistory.restore_history_id) restore_history_id
,max(restorehistory.backup_set_id) backup_set_id
--,max(restorehistory.restore_date) restore_date
,restorehistory.destination_database_name DestDBName
FROM
msdb.dbo.restorehistory

where restore_type = 'D'
group by 
--BackupSet.backup_set_id,
--restorehistory.backup_set_id,
restorehistory.destination_database_name
),


restore_db_backupset as
(


select 

  restorehistory.destination_database_name DestDBName
, restorehistory.restore_date
, restorehistory.restore_type
, backupset.user_name
, backupset.server_name OrigSvrName
, backupset.database_name OrigDBName
, backupset.backup_finish_date
 ,restorehistory.backup_set_id
  

FROM
  msdb.dbo.restorehistory
    INNER JOIN
  most_recent_restore 
  ON most_recent_restore.backup_set_id = restorehistory.backup_set_id and most_recent_restore.restore_history_id = restorehistory.restore_history_id
  
  inner join 
  msdb.dbo.BackupSet
  ON restorehistory.backup_set_id = backupset.backup_set_id

  -- where 

  --DestDBName in ('Dev_ClaimsXpress_4_a','DEV_2_PRD_SQLCLAIMSX_8_11_a')

)

/*

exec sp_describe_first_result_set N'select  restorehistory.destination_database_name DestDBName
, restorehistory.restore_date
, restorehistory.restore_type
 ,restorehistory.backup_set_id from msdb.dbo.restorehistory'

 exec sp_describe_first_result_set N'select 
 user_name
, server_name
, database_name
, backup_finish_date from msdb.dbo.BackupSet'

*/


insert into #most_recent_restore select *  from restore_db_backupset
go

--select * from #most_recent_restore
--go

/* get log restores */
with most_recent_restore_log
as
(
select
restorehistory.restore_history_id restore_history_id
,restorehistory.backup_set_id backup_set_id
--,max(restorehistory.restore_date) restore_date
,restorehistory.destination_database_name DestDBName
FROM
msdb.dbo.restorehistory




where restore_type = 'L'

--group by 
--BackupSet.backup_set_id,
--restorehistory.backup_set_id,
--restorehistory.destination_database_name
),


restore_log_backupset as
(

select 

  restorehistory.destination_database_name DestDBName
, restorehistory.restore_date
, restorehistory.restore_type
, backupset.user_name
, backupset.server_name OrigSvrName
, backupset.database_name OrigDBName
, backupset.backup_finish_date
 ,restorehistory.backup_set_id
  

FROM
  msdb.dbo.restorehistory
    INNER JOIN
  most_recent_restore_log 
  ON most_recent_restore_log.backup_set_id = restorehistory.backup_set_id and most_recent_restore_log.restore_history_id = restorehistory.restore_history_id
  
  inner join 
  msdb.dbo.BackupSet
  ON restorehistory.backup_set_id = backupset.backup_set_id

  --where 

  --DestDBName in ('Dev_ClaimsXpress_4_a','DEV_2_PRD_SQLCLAIMSX_8_11_a')

)
  --create database @most_recent_restore 

  --select *  into #most_recent_restore from restore_db_backupset
  --go

--select * into #most_recent_restore from restore_log_backupset

--select * from restore_data_backupset



	insert into #most_recent_restore 
	
	select 
	lbs.*
	from restore_log_backupset lbs
	
--join most_recent_restore r on r.

	join #most_recent_restore m on m.DestDBName = lbs.DestDBName
	where lbs.restore_date > m.restore_date	

	--where  restore_log_backupset.restore_date > (select max(restore_date) from #most_recent_restore)

	--select * from #most_recent_restore

	select * from #most_recent_restore

	order by DestDBName, restore_date



--where restorehistory.destination_database_name like ('Premium_P2EE') --or 
--restorehistory.destination_database_name like '%CLAIMSXPRESS%'



--group by 
--BackupSet.backup_set_id,
--restorehistory.backup_set_id,
--restorehistory.destination_database_name
--,(restorehistory.restore_type) 
--, (backupset.user_name) 
--, (backupset.server_name) 
--, (backupset.database_name) 
--, (backupset.backup_finish_date) 
--order by restore_date desc
/*
with most_recent_restore_log
as
(
select
max(restorehistory.restore_history_id) restore_history_id
,max(restorehistory.backup_set_id) backup_set_id
--,max(restorehistory.restore_date) restore_date
,restorehistory.destination_database_name DestDBName
FROM
msdb.dbo.restorehistory

where restore_type = 'L'
group by 
--BackupSet.backup_set_id,
--restorehistory.backup_set_id,
restorehistory.destination_database_name
)

select * from msdb.dbo.restorehistory

where 

  destination_database_name in ('DEV_2_PRD_SQLCLAIMSX_8_11_a','Dev_ClaimsXpress_4')

  */