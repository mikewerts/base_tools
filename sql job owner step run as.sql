select sj.name, su.name as 'Owner', sjs.step_name, sjs.step_id as 'Step Number', sjs.database_user_name as 'Step Run As' from msdb.dbo.sysjobs sj
join msdb.dbo.sysjobsteps sjs on sjs.job_id = sj.job_id
join syslogins su on su.sid = sj.owner_sid
--where sjs.database_user_name is not null

/*
WHERE sjs.database_user_name in ('MEMIC1\bmerrill',
'MEMIC1\er1g','MEMIC1\esmh','memic1\gparanich',
'MEMIC1\jtottser',
'MEMIC1\L1T',
'MEMIC1\MEA','MEMIC1\P1A',
'MEMIC1\QSC','MEMIC1\r1g',
'MEMIC1\SMH','MEMIC1\q1r',
'Quinten','Scott')
*/









--where su.name not in ('sa','MEMIC_SimsUser','MEMIC1\EMJW','MEMIC1\svc_prodinsurity')
order by sj.name, sjs.step_id

--select * from msdb.dbo.sysjobsteps sjs

