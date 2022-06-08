SET NOCOUNT ON;

DECLARE cursLogins CURSOR FAST_FORWARD FOR
SELECT name
FROM sys.server_principals
WHERE 
  (LEFT(name, 4) NOT IN ('NT A', 'NT S')
    AND
   TYPE IN ('U', 'G'))
  OR
   (LEFT(name, 2) <> '##'
    AND
   TYPE = 'S');

DECLARE @Login sysname;

OPEN cursLogins;

FETCH FROM cursLogins INTO @Login;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	EXEC sp_help_revlogin @Login;
	PRINT '';

	FETCH NEXT FROM cursLogins INTO @Login;
END

CLOSE cursLogins;
DEALLOCATE cursLogins;