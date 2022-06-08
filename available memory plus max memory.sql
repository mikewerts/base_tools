with com_mem as
(
select	--@@servername, i.*, m.*	
i.committed_kb / 1024 as [Memory Committed (MB)] ,
			i.committed_target_kb / 1024  as [Memory Target (MB)] ,
			m.total_physical_memory_kb / 1024 as [Total Physical Memory - Server (MB)],
			m.available_physical_memory_kb / 1024 as [Total Available Memory - Server (MB)],
			       available_page_file_kb/1024 AS [Available Page File (MB)], 
       system_cache_kb/1024 AS [System Cache (MB)],
			m.system_memory_state_desc AS [System Memory State]
from			sys.dm_os_sys_info as i
cross apply	sys.dm_os_sys_memory as m


), 

buffer_cache_hit_ratio as
(
SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 as BufferCacheHitRatio
FROM sys.dm_os_performance_counters  a
JOIN  (SELECT cntr_value,OBJECT_NAME 
	FROM sys.dm_os_performance_counters  
  	WHERE counter_name = 'Buffer cache hit ratio base'
        AND OBJECT_NAME like '%Buffer Manager%') b ON  a.OBJECT_NAME = b.OBJECT_NAME
WHERE a.counter_name = 'Buffer cache hit ratio'
AND a.OBJECT_NAME like '%Buffer Manager%'
)


select
 [Memory Committed (MB)] ,
[Memory Target (MB)] ,
sc.value as 'Maximum SQL Memory - Instance',
osp.cntr_value/1024 as 'Stolen Server Memory (MB)',
osp2.cntr_value/1024 as 'Lock Memory (MB)',
osp3.cntr_value as 'Page Life Expectancy',
(convert(bigint,sc.value) /1024/ 4) * 300 as 'Reccomended Page Life Expectancy',
[Total Physical Memory - Server (MB)],
[Total Available Memory - Server (MB)],
 [Available Page File (MB)], 
 [System Cache (MB)],
[System Memory State],
buffer_cache_hit_ratio.BufferCacheHitRatio,
si.sqlserver_start_time

from com_mem
outer apply sys.configurations as sc, sys.dm_os_performance_counters as osp, 
sys.dm_os_performance_counters as osp2,  sys.dm_os_performance_counters as osp3, sys.dm_os_sys_info as si, 
buffer_cache_hit_ratio

/*

SELECT *
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE '%Total Server%';

*/

where sc.description = 'Maximum size of server memory (MB)'
--cross apply sys.dm_os_performance_counters as osp
--where 
and osp.[counter_name] = 'Stolen Server Memory (KB)'
and osp2.[counter_name] =  'Lock Memory (KB)'
and osp3.[counter_name] =  'Page life expectancy'
AND osp3.OBJECT_NAME like '%Buffer Manager%'


/*
SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [counter_name] in ('Lock Blocks', 'Lock Blocks Allocated', 'Lock Memory (KB)', 'Lock Owner Blocks')

SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [counter_name] = 'Stolen Server Memory (KB)'

*/

--select 
--m.total_physical_memory_kb as [Physical Memory],
--m.available_physical_memory_kb as [Available Memory]
--from sys.dm_os_sys_memory as m

--SELECT value
----name, value, value_in_use, [description] 
--FROM sys.configurations
----WHERE name like '%server memory%'
--where description = 'Maximum size of server memory (MB)'
--ORDER BY name OPTION (RECOMPILE);

--SELECT object_name, cntr_value
--  FROM sys.dm_os_performance_counters
--  WHERE counter_name IN ('Total Server Memory (KB)', 'Target Server Memory (KB)');

--  SELECT
--(physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,
--(locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,
--(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
--process_physical_memory_low,
--process_virtual_memory_low
--FROM sys.dm_os_process_memory;


/*
As per Microsoft standard, we follow a rule of 300 seconds. If PLE goes less than 300 seconds (5 Minutes), then memory pressure is very high, and we have to take care of the performance side. Still, that calculation was for just 4GB memory allocation to the SQL Server. For your server, it should be different as per the formula. You should worry about the SQL Server instance when PLE goes down than the below calculation:

PLE (Page Life Expectancy) threshold = ((Buffer Memory Allocation (GB)) / 4 ) * 300

https://www.sqlshack.com/page-life-expectancy-ple-in-sql-server/

*/

/*
Target Server Memory (KB) is the amount of memory that SQL Server is willing (potential) to allocate to the buffer pool under its current load. Total Server Memory (KB) is what SQL currently has allocated.

BufferCacheHit Ratio

Ideally, SQL Server would read all pages from the buffer cache and there will be no need to read any from disk. In this case, the Buffer Cache Hit Ratio value would be 100. The recommended value for Buffer Cache Hit Ratio is over 90. When better performance is needed, the minimal acceptable value is 95. A lower value indicates a memory problem

Stolen Server Memory (KB) shows the amount of memory used by SQL Server, but not for database pages. It is used for sorting or hashing operations, or “as a generic memory store for allocations to store internal data structures such as locks, transaction context, and connection information” [3]
There’s no specific threshold value, so it’s recommended to monitor this counter for a while and set a baseline. Note that the value should be close to the Batch Requests/sec value and low compared to the Total Server Memory counter. A high amount of stolen memory indicates memory pressure

Lock Memory (KB) shows the total amount of memory the server is using for locks
The Lock Memory (KB) value should be lower than 24% of the available memory

https://www.sqlshack.com/sql-server-memory-performance-metrics-part-4-buffer-cache-hit-ratio-page-life-expectancy/

https://www.sqlshack.com/sql-server-memory-performance-metrics-part-6-memory-metrics/#:~:text=Stolen%20Server%20Memory%20(KB)%20shows,and%20connection%20information%E2%80%9D%20%5B3%5D

*/

-- You want to see "Available physical memory is high" for System Memory State
-- This indicates that you are not under external memory pressure

-- Possible System Memory State values:
-- Available physical memory is high
-- Physical memory usage is steady
-- Available physical memory is low
-- Available physical memory is running low
-- Physical memory state is transitioning
