drop table #Last_12_Month_Backup
drop table #Last_12_Month_Backup_unpivot
--drop table #Last_12_Month_Backup_trend
drop table #Last_12_Month_Backup_trend_forecast
drop table #trendlines
drop table #CTE_AllIDs

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
	
	--NOT IN (
 --           'master'
 --           ,'msdb'
 --           ,'model'
 --           ,'tempdb'
 --           )

		 = 'ExecutiveReporting'
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

)



insert into #Last_12_Month_Backup_unpivot

select   MonthsAgo, DatabaseName, U.AvgSizeMB, null --, --as Average_Growth_MB  

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


/* new table with forecast */

Create table #Last_12_Month_Backup_trend_forecast
(

MonthsAgo  int
,DatabaseName nvarchar(max)
,AvgSizeMB  decimal(9,2)
,Trend DECIMAL(38, 10) default null


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

/* now calculate the forecast */

with butrend as 
(
SELECT
  --c.ID as 
  MonthsAgo
  ,DatabaseName
 ,AvgSizeMB
 ,Trend
 
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
		from #CTE_AllIDs c
		
		

		/* now outer join to create 24 rows and calculate the forecast */

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
       END


		from joinbutrend

		


	FETCH NEXT from dbcursor into @DatabaseName 

	 END   
CLOSE dbcursor;  
DEALLOCATE dbcursor;	

select * from #Last_12_Month_Backup_trend_forecast
order by DatabaseName, MonthsAgo

--select * from #trendlines
--order by databasename

