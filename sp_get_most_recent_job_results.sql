use master
go


create procedure sp_get_most_recent_job_results @jobname nvarchar(max)
as



/* CTE version */

/* Get the last job step to be run 
This should be the completed job step 0 */


with top_inst as(
select top 1 instance_id, job_id
from msdb.dbo.sysjobhistory
where sysjobhistory.job_id = (select job_id from msdb.dbo.sysjobs where sysjobs.name = @jobname) 
order by instance_id desc
),


/* get the steps from jobsteps */
js as 
(
select sysjobsteps.step_name, sysjobsteps.step_id, sysjobsteps.job_id --,sjh.*  
from msdb.dbo.sysjobsteps
join top_inst on top_inst.job_id = sysjobsteps.job_id
--where sysjobsteps.job_id = (select job_id from sysjobs where sysjobs.name = 'Check DB and Rebuild Indexes')


),

--select * from js

/* get the date the last job was run */

lastdate as
(select max(run_date) as max_date from msdb.dbo.sysjobhistory --where sysjobsteps.job_id = sysjobhistory.job_id and sysjobsteps.step_id = sysjobhistory.step_id 
where msdb.dbo.sysjobhistory.job_id = (select job_id from msdb.dbo.sysjobs where sysjobs.name = @jobname)
--group by job_id
--order by run_date desc, run_time desc
),


/* get the steps run in jobhistory */
sjh as
(select * from msdb.dbo.sysjobhistory --where sysjobsteps.job_id = sysjobhistory.job_id and sysjobsteps.step_id = sysjobhistory.step_id 
join lastdate on lastdate.max_date = run_date --group by job_id
where sysjobhistory.job_id = (select job_id from msdb.dbo.sysjobs where sysjobs.name = @jobname)
--order by run_date desc, run_time desc
),



/*
select step_id, max(run_date) from sysjobhistory --where sysjobsteps.job_id = sysjobhistory.job_id and sysjobsteps.step_id = sysjobhistory.step_id 
where sysjobhistory.job_id = (select job_id from sysjobs where sysjobs.name = 'Check DB and Rebuild Indexes')
group by step_id
*/

/* get the steps in the job process and those that actually ran */
jssjh as
(
select --top 4
 js.step_name as 'Job Step Column Name', js.step_id as 'Job Step Column Step ID', sjh.* from js
 

full outer join sjh on --js.job_id = sjh.job_id and
 js.step_id = sjh.step_id 

)



select [Job Step Column Step ID],  [Job Step Column Name], 
step_id, step_name, 
 convert(datetime, stuff(stuff(cast(run_date as nchar(8)), 7, 0, '-'), 5, 0, '-')) as run_date,
STUFF(STUFF(RIGHT(REPLICATE('0', 6) +  CAST(jssjh.run_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') 'run_time',
       STUFF(STUFF(STUFF(RIGHT(REPLICATE('0', 8) + CAST(jssjh.run_duration as varchar(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':') 'run_duration (DD:HH:MM:SS)  '
,sql_message_id 
,sql_severity 
,message
 from jssjh



 --exec sp_get_most_recent_job_results 'CHECK DB and Rebuild Indexes'


 