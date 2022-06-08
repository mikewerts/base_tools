
--use msdb 
--go

--select * from 
--roles

USE [master]
GO

DECLARE @createlogincommand nvarchar(1000) 
DECLARE @command nvarchar(1000) 
DECLARE @checkcommand nvarchar(1000)
declare @sqlusername nvarchar(100)
declare @defaultdatabase nvarchar(100)
declare @defaultschema nvarchar(100)
declare @role nvarchar(100)
declare @definition nvarchar(100)
declare @databasename nvarchar(100)
declare @majorversion int


--    SQL_BA_Employees

/* common roles */
/*
public
db_owner
db_accessadmin
db_securityadmin
db_ddladmin
db_backupoperator
db_datareader
db_datawriter
db_denydatareader
db_denydatawriter
*/



set @sqlusername = 'MEMIC1\bengle' --MEMIC1\zudy admins
set @defaultschema = 'dbo'
set @defaultdatabase = 'master'
set @role = 'db_owner'
set @definition = 'VIEW DEFINITION'
set @databasename = 'BeaconReconcile'
set @majorversion = (select cast(SERVERPROPERTY('ProductMajorVersion') as int))



--select count(*) from  sys.syslogins where name = @sqlusername


if (select count(*) from  sys.syslogins where name = @sqlusername) = 0
BEGIN
exec --('if (select count(*) from  sys.syslogins where name = '+[@sqlusername]+') = 0 
('CREATE LOGIN ['+@sqlusername+'] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]')
end

/* If this isn't a group, activate the login, otherwise it's activated by default */
if (select isntgroup from sys.syslogins where name = @sqlusername) = 0
begin
exec('ALTER LOGIN ['+@sqlusername+'] enable')
end

/* 1. first make sure the SQL login doesn't have an account under a different user name 
2. Create the user for the database.
3. Check to make sure the new user has been created.
4. Alter the role to add the new user for the table.
5. Check to make sure the new definition is not empty.
6. Add the definition if the SQL user exists in the database.
*/


/* If SQL Server 2008 R2 or below, use sp_addrolemember, otherwise use ALTER ROLE*/ 

if @majorversion > 11

select @command = 'USE ['+@databasename+'] 
   if (select count(*)
   from sys.syslogins l  
   join sys.sysusers u  on l.sid = u.sid
   where l.name = '''+@sqlusername+''') = 0
	BEGIN
		EXEC(''CREATE USER ['+@sqlusername+'] FOR LOGIN ['+@sqlusername+'] WITH DEFAULT_SCHEMA=['+@defaultschema+']'')
	END
	if (select count(*) from  sys.sysusers where name = '''+@sqlusername+''') = 1
	begin
		 EXEC(''ALTER ROLE ['+@role+'] ADD MEMBER ['+@sqlusername+']'') 
		 if '''+@definition+''' <> '''' 
			BEGIN
				EXEC(''GRANT '+@definition+' TO ['+@sqlusername+']'')
			END
		END
   '	

else 

select @command = 'USE ['+@databasename+'] 
   if (select count(*)
   from sys.syslogins l  
   join sys.sysusers u  on l.sid = u.sid
   where l.name = '''+@sqlusername+''') = 0
	BEGIN
		EXEC(''CREATE USER ['+@sqlusername+'] FOR LOGIN ['+@sqlusername+'] WITH DEFAULT_SCHEMA=['+@defaultschema+']'')
	END
	if (select count(*) from  sys.sysusers where name = '''+@sqlusername+''') = 1
	begin
	EXEC sp_addrolemember '''+@role+''', '''+@sqlusername+''';

		 if '''+@definition+''' <> '''' 
			BEGIN
				EXEC(''GRANT '+@definition+' TO ['+@sqlusername+']'')
			END
		END
   '	


--   print @command 

EXEC sp_executesql @command 

   declare @db_name nvarchar(max);
declare @windows_user nvarchar(max);
declare @SQL_user nvarchar(max); 
declare @sqlstr as nvarchar(max); 


/* create the variable for the temp table */
declare @insertstring as nvarchar(max);
declare @inserttable table
(
			[dbname] nvarchar(500),
			[UserName] nvarchar(500), 
			[UserType] nvarchar(500),
			[DatabaseUserName] nvarchar(500),   
			[Role] nvarchar(500),
  
    [PermissionType] nvarchar(500), -- = perm.[permission_name],       
    [PermissionState] nvarchar(500),-- = perm.[state_desc],       
    [ObjectType] nvarchar(500),-- = obj.type_desc,--perm.[class_desc],       
    [ObjectName] nvarchar(500), --= OBJECT_NAME(perm.major_id),
    [ColumnName]  nvarchar(500) --= col.[name]

);



--set @windows_user = 'MEMIC1\SQL_Developer_Employees'

declare db_cursor cursor
for 
	SELECT name from sys.databases
	where state_desc = 'ONLINE'
	and name NOT IN('master', 'model', 'msdb', 'tempdb')
	open db_cursor
	
	fetch next from db_cursor into @db_name

	while @@fetch_status = 0

	begin
	/* first, List all access provisioned to a sql user or windows user/group through a database or application role */

	set @sqlstr = '

		
		Use ['+ @db_name +'] 


		SELECT '''+ @db_name +''',  
    [UserName] = CASE princ.[type] 
                    WHEN ''S'' THEN princ.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
					when ''G'' then princ.[name]
                 END,
    [UserType] = CASE princ.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
					when ''G'' then ''AD Group''
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],       
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]
FROM    
    sys.database_principals princ  
LEFT JOIN
    sys.login_token ulogin on princ.[sid] = ulogin.[sid]
LEFT JOIN        
    sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
    sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
WHERE 
    princ.[type] in (''S'',''U'',''G'')

	/* add any principals to further qualify */
and princ.[name] in ('''+@sqlusername+''')

UNION


		SELECT  
		'''+ @db_name +''',
			[UserName] = CASE memberprinc.[type] 

							WHEN ''S'' THEN memberprinc.[name]
							WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
							when ''G'' then memberprinc.[name]
						 END,
			[UserType] = CASE memberprinc.[type]
							WHEN ''S'' THEN ''SQL User''
							WHEN ''U'' THEN ''Windows User''
							when ''G'' then ''AD Group''
						 END, 
			[DatabaseUserName] = memberprinc.[name],   
			[Role] = roleprinc.[name],   
			[PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,--perm.[class_desc],   
    [ObjectName] = OBJECT_NAME(perm.major_id),
    [ColumnName] = col.[name]  

		FROM    
			sys.database_role_members members
		JOIN
			sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
		JOIN
			sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
		LEFT JOIN
			sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
		LEFT JOIN        
		    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
		LEFT JOIN
			sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
		LEFT JOIN
			sys.objects obj ON perm.[major_id] = obj.[object_id]
			where memberprinc.[name] = '''+@sqlusername+''''
		
		--print @sqlstr
		
									begin try
                                    --print @sql
									insert into @inserttable exec sp_executesql @sqlstr 
									end try
									BEGIN CATCH  
										--print @server_name; 
										print 
										'Error:' 
										+ char(10) 
										+ 'Server ' + @@servername
										+ char(10)
										+ 'Error Number ' + cast(ERROR_NUMBER() as nvarchar) 
										+ char(10)
										+ 'Error Message ' + ERROR_MESSAGE();	
										--+	'ErrorSeverity ' + cast(ERROR_SEVERITY() as nvarchar)    
										--+	'ErrorState ' + cast(ERROR_STATE() as nvarchar)   
 									--	+	'ErrorProcedure ' + cast(ERROR_PROCEDURE() as nvarchar)   
										--+	'ErrorLine ' + cast(ERROR_LINE() as nvarchar)    
																			 

										--SELECT  
										--@server_name,
											--ERROR_NUMBER() AS ErrorNumber  
											--,ERROR_SEVERITY() AS ErrorSeverity  
											--,ERROR_STATE() AS ErrorState  
											--,ERROR_PROCEDURE() AS ErrorProcedure  
											--,ERROR_LINE() AS ErrorLine  
											--,ERROR_MESSAGE() AS ErrorMessage;  
									END CATCH; 

		
	

	--select * from @inserttable

	fetch db_cursor into @db_name
	end

close db_cursor
deallocate db_cursor

select * from @inserttable
where dbname = @databasename 