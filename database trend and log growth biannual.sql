drop table #Last_12_Month_Backup
drop table #Last_12_Month_Backup_unpivot
--drop table #Last_12_Month_Backup_trend
drop table #Last_12_Month_Backup_trend_forecast
drop table #trendlines
drop table #CTE_AllIDs
drop table #Sum_by_database_name
drop table #Get_volume_mount_points
drop table #Get_datafiles
drop table #Get_logfiles
drop table #Get_group_trend
drop table #Get_group_trend_max
drop table #Get_group_trend_next_six
drop table #Get_group_trend_last_six
drop table #Get_group_trend_last_12
drop table #12_Month_Forecast
drop table #12_Before_12_After
drop table #get_database_new


/* old */


Create table #Last_12_Month_Backup
(
DatabaseName nvarchar(max)
    
,[1] NUMERIC(10, 1)
	,[2] NUMERIC(10, 1)
	,[3] NUMERIC(10, 1)
	,[4] NUMERIC(10, 1)
	,[5] NUMERIC(10, 1)
	,[6] NUMERIC(10, 1)
	,[7] NUMERIC(10, 1)
	,[8] NUMERIC(10, 1)
	,[9] NUMERIC(10, 1)
	,[10] NUMERIC(10, 1)
	,[11] NUMERIC(10, 1)
	,[12] NUMERIC(10, 1)
	--,[0] NUMERIC(10, 1)

)






Create table #12_Month_Forecast
(
DatabaseName nvarchar(max)
    
	,[13] NUMERIC(10, 1)
	,[14] NUMERIC(10, 1)
	,[15] NUMERIC(10, 1)
	,[16] NUMERIC(10, 1)
	,[17] NUMERIC(10, 1)
	,[18] NUMERIC(10, 1)
	,[19] NUMERIC(10, 1)
	,[20] NUMERIC(10, 1)
	,[21] NUMERIC(10, 1)
	,[22] NUMERIC(10, 1)
	,[23] NUMERIC(10, 1)
	,[24] NUMERIC(10, 1)
	--,[0] NUMERIC(10, 1)

)

Create table #12_Before_12_After
(
DatabaseName nvarchar(max)
    
	,[-11] NUMERIC(10, 1)
	,[-10] NUMERIC(10, 1)
	,[-9] NUMERIC(10, 1)
	,[-8] NUMERIC(10, 1)
	,[-7] NUMERIC(10, 1)
	,[-6] NUMERIC(10, 1)
	,[-5] NUMERIC(10, 1)
	,[-4] NUMERIC(10, 1)
	,[-3] NUMERIC(10, 1)
	,[-2] NUMERIC(10, 1)
	,[-1] NUMERIC(10, 1)
	,[0] NUMERIC(10, 1)
	,[1] NUMERIC(10, 1)
	,[2] NUMERIC(10, 1)
	,[3] NUMERIC(10, 1)
	,[4] NUMERIC(10, 1)
	,[5] NUMERIC(10, 1)
	,[6] NUMERIC(10, 1)
	,[7] NUMERIC(10, 1)
	,[8] NUMERIC(10, 1)
	,[9] NUMERIC(10, 1)
	,[10] NUMERIC(10, 1)
	,[11] NUMERIC(10, 1)
	,[12] NUMERIC(10, 1)


)




DECLARE @startDate DATETIME;
declare @databasename nvarchar(max);
declare @DatabaseName2 nvarchar(max);
declare @val as int;
set @val = 1


SET @startDate = GetDate();

--insert into #Last_12_Month_Backup



with Last_12_Month_BU_Ave as 
(
SELECT PVT.DatabaseName as DatabaseName 
--,PVT.[-12] - PVT.[-13] as [-13]   
/*
,PVT.[-11] - PVT.[-12]  as [-12]
	,PVT.[-10] - PVT.[-11] as [-11]
	,PVT.[-9] - PVT.[-10] as [-10]
	,PVT.[-8] - PVT.[-9] as [-9]
	,PVT.[-7] - PVT.[-8] as [-8]
	,PVT.[-6] - PVT.[-7] as [-7]
	,PVT.[-5] - PVT.[-6] as [-6]
	,PVT.[-4] - PVT.[-5] as [-5]
	,PVT.[-3] - PVT.[-4] as [-4]
	,PVT.[-2] - PVT.[-3] as [-3]
	,PVT.[-1] - PVT.[-2] as [-2]
	,PVT.[0]  - PVT.[-1] as [-1]
*/
	,PVT.[-12]  as [-12]
	,PVT.[-11] as [-11]
	,PVT.[-10] as [-10]
	, PVT.[-9] as [-9]
	,PVT.[-8] as [-8]
	,PVT.[-7] as [-7]
	,PVT.[-6] as [-6]
	,PVT.[-5] as [-5]
	,PVT.[-4] as [-4]
	,PVT.[-3] as [-3]
	,PVT.[-2] as [-2]
	,PVT.[-1] as [-1]
	--,-- as [0]
FROM (

--DECLARE @startDate DATETIME;
--SET @startDate = GetDate();

    SELECT BS.database_name AS DatabaseName
   ,DATEDIFF(mm, @startDate, BS.backup_start_date) AS MonthsAgo
   --     ,CONVERT(NUMERIC(10, 1), AVG(BF.file_size / 1048576.0)) AS AvgSizeMB
   ,CONVERT(NUMERIC(10, 1), AVG(BS.backup_size / 1048576.0)) AS AvgSizeMB
  FROM msdb.dbo.backupset AS BS
    INNER JOIN msdb.dbo.backupfile AS BF ON BS.backup_set_id = BF.backup_set_id
    WHERE BS.database_name 
	
	NOT IN (
            'master'
            ,'msdb'
            ,'model'
            ,'tempdb'
            )

		 --= 'Beacon'
        AND BS.database_name IN (
            SELECT db_name(database_id)
            FROM master.SYS.DATABASES
            WHERE state_desc = 'ONLINE'
            )
        AND BF.[file_type] = --'L' 
		'D' --for databases
       AND BS.backup_start_date BETWEEN DATEADD(yy, - 1, @startDate)
          AND @startDate
    GROUP BY BS.database_name
       ,DATEDIFF(mm, @startDate, BS.backup_start_date)
    ) AS BCKSTAT
PIVOT(SUM(BCKSTAT.AvgSizeMB) FOR BCKSTAT.MonthsAgo IN (
--         [-13]
		  -- ,
		  [-12]
	,[-11]
	,[-10]
	,[-9]
	,[-8]
	,[-7]
	,[-6]
	,[-5]
	,[-4]
	,[-3]
	,[-2]
	,[-1]
	,[0]
            )) AS PVT
			
--ORDER BY PVT.DatabaseName
)

insert into #Last_12_Month_Backup	select *  from Last_12_Month_BU_Ave

--select * from #Last_12_Month_Backup




Create table #Last_12_Month_Backup_unpivot
(

MonthsAgo  int
,DatabaseName nvarchar(max)
,AvgSizeMB  decimal(9,2)
,trend DECIMAL(38, 10) default null
,slope decimal(9,2)

)



insert into #Last_12_Month_Backup_unpivot

select   MonthsAgo, DatabaseName, U.AvgSizeMB, null, null --, --as Average_Growth_MB  

	from #Last_12_Month_Backup
	unpivot (AvgSizeMB  FOR MonthsAgo IN
	(
	           --[-13]
		  [1] 
	,[2] 
	,[3] 
	,[4] 
	,[5] 
	,[6] 
	,[7] 
	,[8] 
	,[9] 
	,[10] 
	,[11] 
	,[12] 
	))
	as u
	/* placeholder for data from one database */
	--where DatabaseName = 'Beacon'


--	select * from #Last_12_Month_Backup 

/* new table with forecast */

Create table #Last_12_Month_Backup_trend_forecast
(

MonthsAgo  int
,DatabaseName nvarchar(max)
,AvgSizeMB  decimal(9,2)
,Trend DECIMAL(38, 10) default null
,slope DECIMAL(38, 10)


)

/* Create table with sum by database name */

Create table #Sum_by_database_name
(
[database_id] int,
[DatabaseName] nvarchar(max),
[volume_mount_point] nvarchar(512),
[Total Current Database Size] int, 
[Total Projected Size] int,
[Sum Log File Size (current)] int, 
[Sum Total Projected Size] int

)

Create table #Get_volume_mount_points
(
	volume_mount_point  nvarchar(512),
	volume_id nvarchar(512),
	DB_Size int,
	total_MB int,
    available_MB int
)	

Create table #Get_datafiles
(
	[database_id] int
	--,[DatabaseName] nvarchar(max)
	,[volume_mount_point] nvarchar(512)
	,[Database Size] int
	,[available_MB] int
)

Create table #Get_logfiles
(
	[database_id] int
--	,[DatabaseName] nvarchar(max)
	,[volume_mount_point] nvarchar(512)
	,[Database Size] int
	,[available_MB] int
)

Create table #Get_group_trend

(
--[MonthsAgo] int,
[database_id] int,
--[DatabaseName] nvarchar(max),
[Size] int,
--[Projected Size 12 Months (MB)] int,
[Slope] decimal(9,2)


)

Create table #Get_group_trend_max

(
[database_id] int,
[DatabaseName] nvarchar(max),
[Projected Size 12 Months (MB)] int,
[Slope] decimal(9,2)


)


Create table #Get_group_trend_next_six

(
[database_id] int,
[DatabaseName] nvarchar(max),
[Projected Size 12 Months (MB)] int,
[Slope] decimal(9,2)


)

Create table #Get_group_trend_last_six

(
[database_id] int,
[DatabaseName] nvarchar(max),
[Projected Size 12 Months (MB)] int,
[Slope] decimal(9,2)


)

Create table #Get_group_trend_last_12

(
[database_id] int,
[DatabaseName] nvarchar(max),
[Projected Size 12 Months (MB)] int,
[Slope] decimal(9,2)


)

 Create table #get_database_new
(

DatabaseName nvarchar(max)
,[Size 12 Months Ago (MB)]  int
,[Size 6 Months Ago (MB)]  int
,[Database Size (MB)]  int
,[Projected Size 6 Months (MB)]  int
,[Projected Size 12 Months (MB)]  int


)


/* create static temp table with 24 sequential numeric rows to join and show forecast data in months */




declare @id int 
set @id = 1



create table #CTE_AllIDs 
(ID int
);
while @id < 25 
begin 
	
	insert  into #CTE_AllIDs(ID) select @id -- (@id) 
	set @id = @id + 1
	--print @id
end

/* create table for linear forecasting components */

create table #trendlines 
(
databasename nvarchar(max),
SampleSize INT, 
sumX   DECIMAL(38, 10),
sumY   DECIMAL(38, 10),
sumXX   DECIMAL(38, 10),
sumYY   DECIMAL(38, 10),
sumXY   DECIMAL(38, 10),
--trend DECIMAL(38, 10)
);


--select * from #CTE_AllIDs

-- declare all variables
DECLARE @sample_size INT; 
DECLARE @intercept  DECIMAL(38, 10);
DECLARE @slope   DECIMAL(38, 10);
DECLARE @sumX   DECIMAL(38, 10);
DECLARE @sumY   DECIMAL(38, 10);
DECLARE @sumXX   DECIMAL(38, 10);
DECLARE @sumYY   DECIMAL(38, 10);
DECLARE @sumXY   DECIMAL(38, 10);
declare @trend DECIMAL(38, 10);

/* declare cursor to calculate sample size and the different sums for each database */

declare dbcursor cursor
for 
select DatabaseName from #Last_12_Month_Backup 
 open  dbcursor  

 fetch next from dbcursor
 into @DatabaseName

 while @@fetch_status = 0
 begin

SELECT
  @sample_size = COUNT(*)
 ,@sumX   = SUM(MonthsAgo)
 ,@sumY   = SUM([AvgSizeMB])
 ,@sumXX   = SUM(MonthsAgo*MonthsAgo)
 ,@sumYY   = SUM([AvgSizeMB]*[AvgSizeMB])
 ,@sumXY   = SUM(MonthsAgo*[AvgSizeMB])

 /* get the slope ind intercept for each database */
FROM #Last_12_Month_Backup_unpivot
where DatabaseName = @DatabaseName
--where DatabaseName = 'Beacon'

insert into #trendlines
SELECT
  databasename = @databasename
  ,SampleSize   = @sample_size  
 ,sumX    = @sumX   
 ,sumY		=@sumY   
 ,SumXX    = @sumXX   
 ,SumYY    = @sumYY   
 ,SumXY    = @sumXY



 -- calculate the slope and intercept
SET @slope = CASE WHEN @sample_size = 1
    THEN 0 -- avoid divide by zero error
    ELSE (@sample_size * @sumXY - @sumX * @sumY) / (@sample_size * @sumXX - POWER(@sumX,2))
    END;
SET @intercept = (@sumY - (@slope*@sumX)) / @sample_size;
--Now that we have found the slope and the intercept, we can easily calculate the linear trendline in each x-coordinate. We store the results in the temp table.

--declare @trend DECIMAL(38, 10)
	
/* calculate trend line */
	UPDATE #Last_12_Month_Backup_unpivot
	SET Trend = (@slope*MonthsAgo) + @intercept
	where DatabaseName = @DatabaseName;

	update #Last_12_Month_Backup_unpivot
	set slope = @slope
	where DatabaseName = @DatabaseName;

/* now calculate the forecast */

with butrend as 
(
SELECT
  --c.ID as 
  MonthsAgo
  ,DatabaseName
 ,AvgSizeMB
 ,Trend
 ,slope
 
	FROM  #Last_12_Month_Backup_unpivot --#CTE_AllIDs   c 
	where DatabaseName = @DatabaseName
	--where DatabaseName = 'Beacon'
	),

joinbutrend as
(


	--insert into #Last_12_Month_Backup_trend_forecast
	select 
	c.ID as MonthsAgo
	,butrend.DatabaseName
	,butrend.AvgSizeMB
	,butrend.Trend
	,butrend.slope
		from #CTE_AllIDs c
		
		

		/* now outer join to calculate the forecast for 12 months out*/

	   left JOIN butrend ON c.ID = butrend.MonthsAgo	
	   
	   ) 

	   --select * from joinbutrend
	  

	 insert into #Last_12_Month_Backup_trend_forecast

	 
	   select joinbutrend.MonthsAgo - 12 as [month], @DatabaseName, joinbutrend.AvgSizeMB, -- Trend, --from joinbutrend

	   Trend = Case when  joinbutrend.MonthsAgo <= (SELECT MAX(joinbutrend.MonthsAgo) from joinbutrend where DatabaseName = @DatabaseName)
        THEN joinbutrend.Trend
       
       WHEN joinbutrend.MonthsAgo > (SELECT MAX(joinbutrend.MonthsAgo) from joinbutrend where DatabaseName = @DatabaseName)
        THEN (@slope * (MonthsAgo % 100)) + @intercept
      -- ELSE NULL
       END,
	   slope = 
	    /* slope < 1 set to 1 */
	   case when ((@slope * (24 % 100)) + @intercept) /((@slope * (12 % 100)) + @intercept) < 1
		then 1
	  /* slope > 1 */
	   else ((@slope * (24 % 100)) + @intercept) /((@slope * (12 % 100)) + @intercept)
	   end



		from joinbutrend

		


	FETCH NEXT from dbcursor into @DatabaseName 

	 END   
CLOSE dbcursor;  
DEALLOCATE dbcursor;	

--select * from #Last_12_Month_Backup_unpivot;

/*

select *
,CASE WHEN SampleSize = 1
    THEN 0 -- avoid divide by zero error
    ELSE ((SampleSize * sumXY) - (sumX * sumY)) / ((SampleSize * sumXX) - POWER(sumX,2))
    END as 'Slope'

 from #trendlines;

 */
 
 --select * from #Last_12_Month_Backup_trend_forecast;


 /* pivot on DatabaseName to get trend */

 with db_trend
 as
 (
 SELECT PVT.DatabaseName
	--PVT.BCKSTAT.Trend 
    

	--,PVT.[-11] as [-11]
	--,PVT.[-10] as [-10]
	--, PVT.[-9] as [-9]
	--,PVT.[-8] as [-8]
	--,PVT.[-7] as [-7]
	--,PVT.[-6] as [-6]
	--,PVT.[-5] as [-5]
	--,PVT.[-4] as [-4]
	--,PVT.[-3] as [-3]
	--,PVT.[-2] as [-2]
	--,PVT.[-1] as [-1]
	--,PVT.[0] as [0]
	,PVT.[1] as [1]
	,PVT.[2] as [2]
	,PVT.[3] as [3]
	,PVT.[4] as [4]
	,PVT.[5] as [5]
	,PVT.[6] as [6]
	,PVT.[7] as [7]
	,PVT.[8] as [8]
	,PVT.[9] as [9]
	,PVT.[10] as [10]
	,PVT.[11] as [11]
	,PVT.[12] as [12]
	
FROM (


			select MonthsAgo, DatabaseName, Trend  from #Last_12_Month_Backup_trend_forecast tf		
    GROUP BY tf.DatabaseName, MonthsAgo, Trend
        --,DATEDIFF(mm, @startDate, BS.backup_start_date)
    ) AS BCKSTAT
PIVOT(sum(BCKSTAT.Trend) FOR BCKSTAT.MonthsAgo--, BCKSTAT.DatabaseName, BCKSTAT.Trend 
IN 
--PIVOT(0) FOR BCKSTAT.MonthsAgo IN 
(
           
	--[-11]
	--,[-10]
	--,[-9]
	--,[-8]
	--,[-7]
	--,[-6]
	--,[-5]
	--,[-4]
	--,[-3]
	--,[-2]
	--,[-1]
	--,[0]
	--,
	[1]
	,[2]
	,[3]
	,[4]
	,[5]
	,[6]
	,[7]
	,[8]
	,[9]
	,[10]
	,[11]
	,[12]
            )) AS PVT
--ORDER BY PVT.DatabaseName
)

insert into #12_Month_Forecast select * from db_trend

--select * from #12_Month_Forecast

--drop table #12_Before_12_After
insert into #12_Before_12_After 
select L12.DatabaseName
	,[1]
	,[2]
	,[3]
	,[4]
	,[5]
	,[6]
	,[7]
	,[8]
	,[9]
	,[10]
	,[11]
	,[12]
	,[13]  
	,[14] 
	,[15] 
	,[16] 
	,[17] 
	,[18] 
	,[19] 
	,[20] 
	,[21] 
	,[22] 
	,[23] 
	,[24] 



from #Last_12_Month_Backup L12
join #12_Month_Forecast N12
on n12.DatabaseName = L12.DatabaseName
;


/* now get the current size of the log files */
with 
log_files as(

SELECT -- s.[database_id]

	-- @@SERVERNAME as 'ServerName'
	 -- s.[name] as 'FileName'
	 -- ,
	 s.database_id as 'database_id',
	 
	--	s.name as 'DatabaseName', 
		volume_mount_point as 'volume_mount_point'

		/* sum for more than one log file */
	  ,sum([size] * 8/1024)
	   as 'Log Size'
	  /* get one value for available bytes */
	  ,max(available_bytes)/1024/1024 AS 'available_MB'
	 

  FROM [master].[sys].[master_files] s

 -- select * from sys.databases





    -- with rollup
  join sys.databases sd on sd.database_id = s.database_id
  CROSS APPLY
    sys.dm_os_volume_stats(s.database_id, s.file_id)
	
	where sd.database_id  > 4
	--where s.name not like 'temp%'
  and s.[type] = 1
  --and sd.name <> 'tempdb'
  and sd.state_desc = 'ONLINE'
 -- group by  sd.name 

 group by s.database_id, volume_mount_point
 
  )

  insert into #Get_logfiles
select * from log_files;


--select * from #Get_logfiles;

  /* now get the data files */

   
with data_files as(

SELECT
s.database_id as 'database_id',
--s.name as 'DatabaseName',
 volume_mount_point as 'volume_mount_point'
   
	  ,
	  /* sum if more than one file */
	  sum( [size] * 8/1024)
	  as 'Database Size'
	  /* get one value for available bytes */
	  ,max(available_bytes)/1024/1024 AS 'available_MB'
	 

 --select *  
 FROM [master].[sys].[master_files] s

    -- with rollup
  join sys.databases sd on sd.database_id = s.database_id
    CROSS APPLY
    sys.dm_os_volume_stats(s.database_id, s.file_id)
	where sd.database_id  > 4
	
	--s.name not like 'temp%'
  and s.[type] = 0
  --and 
  --and sd.name <> 'tempdb'
--  and sd.state_desc = 'ONLINE'
 -- group by  sd.name 

 group by s.database_id, volume_mount_point
 
  )



insert into #Get_datafiles
select * from data_files;

--select * from #Get_datafiles;



with group_trend as(
select s.database_id
--, 
--DatabaseName

/* for more than one logical data file, get the sum of all files */
,sum([size] * 8/1024)  as 'Size' --, cast((Trend) as int) as 'Projected Size 12 Months (MB)' 
/* if there is more than one logical data file, get only one value */
,max(slope) as 'Slope'

--sum(c.[Database Size]) as 'Current Database Size', 
--sum(c.[Log Size]) as 'Total Log File Size' 
from #Last_12_Month_Backup_trend_forecast
--join master.SYS.DATABASES m on db_name(m.database_id) = DatabaseName
join [master].[sys].[master_files] s on db_name(s.database_id) = DatabaseName 


--join log_files on log_files.DatabaseName = #Last_12_Month_Backup_trend_forecast.DatabaseName
where MonthsAgo = 12
and s.type_desc = 'ROWS'

group by s.database_id 
)

--select * from group_trend

insert into #Get_group_trend
select * from group_trend -- where MonthsAgo = 12

--select * from #Get_group_trend
;


 -- select * from #Last_12_Month_Backup_trend_forecast

  /* sum the trendlines and group with rollup */

--  select * from #Get_group_trend;

 with get_database_new as(
  select 
  
  [12ba].DatabaseName,
 sum([12ba].[-11]) as 'Size 12 Months Ago',
  sum([12ba].[-5]) as 'Size 6 Months Ago',
  sum(ggt.[Size]) as 'Size', 

 
	case when (sum([12ba].[0]) < sum(ggt.[Size]))
	/* trendline lags behind current DB size */
	then sum(cast((ggt.[Size]) * (1 + ([ggt].slope -1) /2) as int))
	else 
	/* use trendline */
	sum(cast([12ba].[6] as int))
	end
	as 'Projected Size 6 Months (MB)', 
	
	/* get projected size 12 months */
	case when (sum([12ba].[0]) < sum(ggt.[Size]))
	/* trendline lags behind current DB size */
	then sum(cast((ggt.[Size]) * [ggt].slope as int))
	else 
	/* use trendline */
	cast(sum([12ba].[12]) as int)
	end as 'Projected Size 12 Months (MB)'

 
  from #12_Before_12_After [12ba]
  
 -- join #Get_datafiles gd on gd.DatabaseName = [12ba].DatabaseName

--  join [master].[sys].[master_files] s on db_name(s.database_id) = DatabaseName 

  join #Get_group_trend [ggt] on  db_name([ggt].database_id) = [12ba].DatabaseName

  group by [12ba].DatabaseName
  )
 -- select *  from get_database_new
 -- order by databasename;
   
 insert into #get_database_new select *  from get_database_new

 select * from #get_database_new
 order by databasename;

-- ,[Size 12 Months Ago (MB)]  int
--,[Size 6 Months Ago (MB)]  int


 select sum([Size 12 Months Ago (MB)]) as [Size 12 Months Ago (MB)], 
 sum([Size 6 Months Ago (MB)]) as [Size 6 Months Ago (MB)],  
 sum([Database Size (MB)]) as [Database Size (MB)],
 sum([Projected Size 6 Months (MB)]) as [Projected Size 6 Months (MB)],
 sum([Projected Size 12 Months (MB)]) as [Projected Size 12 Months (MB)]
 from #get_database_new
 --group by DatabaseName

 -- group by get_database_new.DatabaseName,
 --    get_database_new.[Size 12 Months Ago],
	--get_database_new.[Size 6 Months Ago],
	--get_database_new.[Current Database Size]
	--, 
	--get_database_new.'Projected Size 6 Months (MB)',
	--get_database_new.'Projected Size 12 Months (MB)'





;
 
 /* enter current size, projected size, and mount points for data and log files */


 --select * from #Get_datafiles
 --;
 --select * from #Get_logfiles
 --;

 --select gd.*, gl.*, gdn.* from  #get_database_new gdn
 --join #Get_datafiles gd on db_name(gd.database_id) = gdn.DatabaseName 
 --join #Get_logfiles gl on db_name(gl.database_id) = gdn.DatabaseName

 --;

 /*

  sum([Database Size (MB)]) as [Database Size (MB)],
 sum([Projected Size 6 Months (MB)]) as [Projected Size 6 Months (MB)],
 sum([Projected Size 12 Months (MB)]) as [Projected Size 12 Months (MB)]

 */

 with growth_by_volume as
 (
	select -- gd.*, gl.*, gdn.* 
	gd.volume_mount_point as 'Volume Mount Point',
	sum(cast(gd.[Database Size] as int)) as 'Current Database Size', 
	0 as 'Total Log File Size (current)',
	max(gd.[available_MB]) as 'Available MB',
	sum(cast(gdn.[Projected Size 6 Months (MB)] as int)) as 'Projected Size 6 Months (MB)',
	sum(cast(gdn.[Projected Size 12 Months (MB)] as int)) as 'Projected Size 12 Months (MB)'
	from  #get_database_new gdn
	
 join #Get_datafiles gd on db_name(gd.database_id) = gdn.DatabaseName 


-- where gdn.DatabaseName = (select distinct db_name(database_id) from #Get_datafiles) gd
 --join #Get_logfiles gl on db_name(gl.database_id) = gdn.DatabaseName
 group by gd.volume_mount_point

  
 union

 select 
		gl.volume_mount_point as 'Volume Mount Point',
		0 as 'Current Database Size',
		sum(cast(gl.[Database Size] as int)) as 'Total Log File Size (current)', 
		max(gl.[available_MB]) as 'Available MB',
		0 as 'Projected Size 6 Monts (MB)',
		0 as 'Projected Size 12 Months (MB)'
		

	from  #get_database_new gdn
	
-- join #Get_datafiles gd on db_name(gd.database_id) = gdn.DatabaseName 
 join #Get_logfiles gl on db_name(gl.database_id) = gdn.DatabaseName
 group by gl.volume_mount_point
 
 
 )

-- select * from growth_by_volume

 select [Volume Mount Point], sum([Current Database Size]) as 'Current Database Size', 

sum([Projected Size 6 Months (MB)]) as 'Projected Size 6 Months (MB)',
sum([Projected Size 12 Months (MB)]) as 'Projected Size 12 Months (MB)', 

sum([Total Log File Size (current)]) as 'Total Log Size',
sum([Projected Size 6 Months (MB)]) + sum([Total Log File Size (current)]) as 'Total Projected Size (6 Months)',
sum([Projected Size 12 Months (MB)]) + sum([Total Log File Size (current)]) as 'Total Projected Size (12 Months)',
sum([Available MB]) as 'Available MB',
sum([Available MB]) - (sum([Projected Size 6 Months (MB)]) - sum([Current Database Size])) as 'Available MB (6 Months)',
sum([Available MB]) - (sum([Projected Size 12 Months (MB)]) - sum([Current Database Size])) as 'Available MB (12 Months)'
from growth_by_volume
group by [Volume Mount Point]

/* old */

/*
with projected_growth_volume as (
select --#Get_group_trend.database_id,
#Get_datafiles.volume_mount_point as 'Volume Mount Point',
sum(cast(#Get_datafiles.[Database Size] as int)) as 'Current Database Size', 
0 as 'Total Log File Size (current)',
case when sum(#Get_group_trend.[Projected Size 12 Months (MB)]) < sum(#Get_datafiles.[Database Size])
/* trendline lags behind current DB size */
then sum(cast(#Get_datafiles.[Database Size] * slope as int))
else 
/* use trendline */
sum(cast(#Get_group_trend.[Projected Size 12 Months (MB)] as int))
end as 'Projected Size 12 Months (MB)',
max(#Get_datafiles.[available_MB]) as 'Available MB'

from #Get_group_trend
join #Get_datafiles on #Get_datafiles.[database_id] = #Get_group_trend.[database_id] 
group by #Get_datafiles.volume_mount_point

union all
select 
#Get_logfiles.volume_mount_point as 'Volume Mount Point',
0 as 'Current Database Size',
sum(cast(#Get_logfiles.[Database Size] as int)) as 'Total Log File Size (current)', 
0 as 'Projected Size 12 Months (MB)',
max(#Get_logfiles.[available_MB]) as 'Available MB'

--sum(slope)
from #Get_group_trend
--join #Get_datafiles on #Get_datafiles.[database_id] = #Get_group_trend.[database_id]
join #Get_logfiles on #Get_logfiles.[database_id] = #Get_group_trend.[database_id]

group by #Get_logfiles.volume_mount_point
--group by #Get_group_trend.DatabaseName
--group by rollup(group_trend.DatabaseName) 

)



select [Volume Mount Point], sum([Current Database Size]) as 'Current Database Size', 
sum([Projected Size 12 Months (MB)]) as 'Projected Size 12 Months (MB)', 
sum([Total Log File Size (current)]) as 'Total Log Size',
sum([Projected Size 12 Months (MB)]) + sum([Total Log File Size (current)]) as 'Total Projected Size (12 Months)',
max([Available MB]) as 'Available MB',
max([Available MB]) - (sum([Projected Size 12 Months (MB)]) - sum([Current Database Size])) as 'Available MB (12 Months)'
from projected_growth_volume
group by [Volume Mount Point]


*/





--select * from #Get_group_trend

--select * from #Get_datafiles

--select * from #Get_logfiles

--select * from #Sum_by_database_name






