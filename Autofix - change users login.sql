
--exec sp_change_users_login 'Report'

declare @fixname nvarchar(1000)

declare @usernames as table
(
username nvarchar(1000),
userSID nvarchar(1000)
)

insert into @usernames
exec sp_change_users_login 'Report'

select * from @usernames

declare fixusernames cursor for
	select username from @usernames

	open fixusernames

	fetch next from fixusernames into @fixname

	while @@fetch_status = 0
	begin

		EXEC sp_change_users_login 'Auto_Fix', @fixname

		fetch next from fixusernames into @fixname

	end
	close fixusernames
	deallocate fixusernames

exec sp_change_users_login 'Report'

--select * from master..syslogins


