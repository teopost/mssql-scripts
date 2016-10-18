create proc [dbo].[wedo_sp_rename_defaults]
as
DECLARE @TableName VARCHAR(255)
DECLARE @ConstraintName VARCHAR(255)
DECLARE @ColumnName VARCHAR(255)
DECLARE @NewDefaultName VARCHAR(255)

begin
SET NOCOUNT on
DECLARE constraint_cursor CURSOR
    FOR 
        select 
		   b.name  AS table_name, 
		   c.name  AS constraint_name, 
		   a.name  AS column_name,
		   'DF_' + b.name + '-' + a.name  as new_default_name
		from 
           sys.all_columns a 
		      inner join sys.tables b  on  a.object_id = b.object_id
              inner join sys.default_constraints c on a.default_object_id = c.object_id
        where 
            b.name <> 'sysdiagrams'
            and b.type = 'U'

 
OPEN constraint_cursor
FETCH NEXT FROM constraint_cursor INTO @TableName, @ConstraintName, @ColumnName, @NewDefaultName

WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @SqlScript VARCHAR(255) = ''
        SET @SqlScript = 'sp_rename [' + @ConstraintName + '], [' + @NewDefaultName + '] ,' +  '''object'''
        EXEC(@SqlScript)
		--PRINT  @SqlScript
		--PRINT  @SqlScript
		PRINT @ConstraintName
		 
        FETCH NEXT FROM constraint_cursor INTO @TableName, @ConstraintName, @ColumnName,  @NewDefaultName
    END 
CLOSE constraint_cursor;
DEALLOCATE constraint_cursor;
end
go
