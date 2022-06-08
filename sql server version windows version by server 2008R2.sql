


with version_support_dates as
(
select * from (

values('13',  '6/1/2016',	'7/13/2021',	'7/14/2026',	'13.0.5850.14 (SP2 CU15)'),
('12',  '5/6/2014',	'7/9/2019',	'7/9/2024',    '12.0.6372.1 (SP3 CU4 + Security Update)'),
('11',  '5/20/2012',	'7/11/2017',	'7/12/2022',	'11.0.7493.4 (Security for SP4 GDR)'

)
) as a([Major Version Number],
[Lifecycle Start Date] ,
[Mainstream Support End Date] ,
[Extended Support End Date] ,
[Latest Service Pack Available])
),

--select * from version_support_dates


versions

as
(
SELECT @@servername as 'Server', 
isnull(serverproperty('InstanceName'), @@servername) as 'Instance', 
substring(@@VERSION, 1, CHARINDEX('-', @@VERSION) - 1) +  ' (' + convert(nvarchar(3), SERVERPROPERTY ('productlevel')) + ')' AS 'SQL Server Version',   
SERVERPROPERTY('productversion') as 'Version Number', 
SERVERPROPERTY('ProductMajorVersion') AS 'Major Version Number', 
SERVERPROPERTY('ProductMinorVersion') AS 'Minor Version Number',

SERVERPROPERTY ('productlevel') as 'Service Pack' --, SERVERPROPERTY('EngineEdition'), SERVERPROPERTY('ProductBuild'),
/* hard code - none of our 2008 R2 has replication */
,'' as 'Listener'
--, dbstate.database_id
--, DB_NAME(dbstate.database_id) as 'Database Name'
--, dbstate.[SQL Compatibility Level]
--, dbstate.[Is HA]
,serverproperty('edition') as 'Windows Edition'
,case when windows_release = '10.0' then 'Windows Server 2016	'
 when windows_release = '6.3' then 'Windows Server 2012 R2'
  when windows_release =  '6.2' then 'Windows Server 2012'
   when windows_release = '6.1' then 'Windows Server 2008 R2'
    when windows_release = '6.0' then 'Windows Server 2008'
	 when windows_release = '5.2' then 'Windows Server 2003'
else 'Unknown' 
end
as 'Windows Version'
, windows_service_pack_level, windows_sku, os_language_version  
FROM sys.dm_os_windows_info
--left join select * from sys.databases
--outer apply (select dns_name from sys.availability_group_listeners) agname

)

/*
SQL Server 2012	5/20/2012	7/11/2017	7/12/2022
SQL Server 2014	5/6/2014	7/9/2019	7/9/2024
SQL Server 2016	6/1/2016	7/13/2021	7/14/2026
SQL Server 2017	9/29/2017	10/11/2022	10/12/2027
SQL Server 2019	11/4/2019	1/7/2025	1/8/2030

Version: Lifecycle Start Date Mainstream support end: Extended support end: LATEST UPDATE
13  6/1/2016	7/13/2021	7/14/2026	13.0.5850.14 (SP2 CU15)
12  5/6/2014	7/9/2019	7/9/2024    12.0.6372.1 (SP3 CU4 + Security Update)
11  5/20/2012	7/11/2017	7/12/2022	11.0.7493.4 (Security for SP4 GDR)

?SQL Server 2008 R2 Version: 10.50
Mainstream support end: 8 July 2014
Extended support end: 9 July 2019	10.50.1600.1	10.50.2500	10.50.4000	10.50.6000		10.50.6560.0 (KB4057113)

*/



select versions.*, 
case when
versions.Listener = '' then 'NO' else 'YES' end
as 'Is HA',

[Lifecycle Start Date] ,
[Mainstream Support End Date] ,
[Extended Support End Date] ,
[Latest Service Pack Available]

from versions
left join version_support_dates vsd on vsd.[Major Version Number] = versions.[Major Version Number]

--left join replica_state on versions.[Database Name] = replica_state.[Database Name]







