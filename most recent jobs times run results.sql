use msdb 


;
with recent_job
as
(
select
--top 1
sj.name as 'job name',
step_id,
step_name, 
case when run_status = 0 then 'Failed'
when run_status = 1 then 'Succeeded'
when run_status = 2 then 'Retry'
when run_status = 3 then 'Canceled'
when run_status = 4 then 'In Progress'
end as 'Run Status',
--jh.start_time,
dbo.agent_datetime(run_date,run_time) as 'DateTime Start'
--,dbo.agent_datetime(run_date,run_time+(run_duration%100 )) 

,DATEADD(second,

[run_duration]/10000*3600+[run_duration]%10000/100*60+[run_duration]%100,

STR(run_date,8)+' '+STUFF(STUFF(RIGHT(1000000+run_time,6),5,0,':'),3,0,':')) as 'DateTime Finish'
,run_duration/10000 as run_duration_hours_only --hours
,run_duration/100%100 as run_duration_minutes_only --minutes
,run_duration%100 as run_duration_seconds_only --seconds
,(run_duration/10000 * 60 * 60) + -- hours as seconds
(run_duration/100%100 * 60) + --minutes as seconds
(run_duration%100 ) as run_duration_total_seconds --seconds
-- ,
from sysjobhistory jh
join sysjobs sj on sj.job_id = jh.job_id
--where sj.name = 'CHECK DB and Rebuild Indexes'
/*  new name */
--where run_status = 0
and step_id = 0
--where sj.name = 'Ebix_Export_Temp'
--and dbo.agent_datetime(run_date,run_time) between '08/11/2020' and '08/12/2020'
--and step_id =0
--and sj.name <> 'ISO-Import ISO Response Files'

--where sj.name = 'Copy and Sync Logins' --, 'Job 050 - Import Processing Procedures',  'Job 100 - Load Procedures', 'Job 101 - Reports Verify Beacon Reconcile Coverage State]',
--'Job 110 - Transfer Data')
--and step_name = '(Job Outcome)'
--group by sj.name
--order by run_date desc , run_time desc

)

select -- top 1 with ties
[job name], step_id, step_name, [Run Status], [DateTime Start], [DateTime Finish], run_duration_hours_only, run_duration_seconds_only, run_duration_total_seconds
,DATEdiff(hh,[DateTime Start], getdate()) as 'Hours since job run'
from recent_job 
--where [job name] = 'Monthend SSIS files Import'
--where DATEdiff(hh,[DateTime Start], getdate()) <= 24
--and [Run Status]= 'Failed'
--order by [DateTime Start] desc
order by row_number() over (partition by [job name] order by [DateTime Start] desc)
/*
group by [job name],
step_id, step_name, [Run Status],  [DateTime Start], 
[DateTime Finish], run_duration_hours_only, run_duration_seconds_only, run_duration_total_seconds
order by [DateTime Start] desc

*/

select count(*) from sysjobs sj
join 
sysjobschedules sjs on sjs.job_id = sj.job_id
join 
sysschedules ss on ss.schedule_id = sjs.schedule_id
where ss.enabled  = 1


 