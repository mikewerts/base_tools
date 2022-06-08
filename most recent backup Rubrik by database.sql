				with cte as(	 SELECT -- top 1
				
				a.database_name 
									
					--,convert (varchar, a.[backup_finish_date], 101) as 'finish_date'
					--,convert (varchar, a.[backup_finish_date], 108) as 'finish_time'
					,a.[backup_finish_date]

					,convert(decimal, (a.backup_size/(POWER(1024,2)))) as 'backup_size'
					--,a.backup_size		
							
					,b.physical_device_name
					
					, case when 
					b.device_type = 2 then 'Disk'
					when b.device_type = 5 then 'Tape'
					when b.device_type = 7 then 'Virtual device'
					when b.device_type = 105 then 'A permanent backup device'
					else 'Other'
					end as 'Device_Type'

					from msdb.dbo.backupset a 
					join msdb.dbo.backupmediafamily b
						on a.media_set_id = b.media_set_id

						where backup_start_date between convert(varchar, getdate() -1, 112)
						and convert(varchar, getdate(), 112)

						
					--and (device_type = 7)
					and a.type = 'D'
					
					--and physical_device_name not like '{%'
					
						and family_sequence_number = 1



)

select 
database_name, 
max(backup_finish_date) as 'Most Recent Backup',
max(backup_size),
max(physical_device_name) as 'Physical Device Name',
max(device_type) as 'Virtual Device'
from cte 
group by database_name
--order by [backup_finish_date] desc

