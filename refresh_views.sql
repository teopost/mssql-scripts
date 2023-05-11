CREATE PROCEDURE dbo.RefreshAllViews
    @databaseName nvarchar(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @viewName nvarchar(128)
    DECLARE @sql nvarchar(max)
    DECLARE view_cursor CURSOR FOR 
	SELECT TABLE_NAME
    FROM POKER_APP.INFORMATION_SCHEMA.VIEWS 
	WHERE TABLE_CATALOG = @databaseName

    OPEN view_cursor

    FETCH NEXT FROM view_cursor INTO @viewName

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = 'USE ' + QUOTENAME(@databaseName) + '; EXEC sp_refreshview ''' + @viewName + ''''
        EXEC sp_executesql @sql
        PRINT 'Aggiornati i metadati della vista ' + @viewName + '.'
        FETCH NEXT FROM view_cursor INTO @viewName
    END

    CLOSE view_cursor
    DEALLOCATE view_cursor
END
