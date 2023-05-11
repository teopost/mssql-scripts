/* Mostra gli indici da ricompilare 1 */
SELECT  'ALTER INDEX ' + i.name +  ' ON ' +  t.name + ' REBUILD;',
        t.name 'TableName',
        i.name 'IndexName',
        frag.avg_fragmentation_in_percent 'Percent Fragmented'
FROM    sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) frag
JOIN    sys.tables t
ON      frag.object_id = t.object_id
JOIN    sys.indexes i
ON      frag.index_id = i.index_id
AND     frag.object_id = i.object_id
WHERE   frag.page_count > 100
AND     frag.avg_fragmentation_in_percent > 10
AND     i.type != 0
AND     t.name != 'ThreadActionCount'
ORDER BY frag.avg_fragmentation_in_percent DESC

/* Mostra gli indici da ricompilare 2 */
SELECT 
    OBJECT_NAME(A.object_id) AS TableName, 
    A.index_id, 
    A.avg_fragmentation_in_percent 
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') A
INNER JOIN 
    sys.objects B ON A.object_id = B.object_id
WHERE 
    A.avg_fragmentation_in_percent > 30 AND 
    B.type = 'U' 
ORDER BY 
    A.avg_fragmentation_in_percent DESC

/* Stored procedure da creare su master */
CREATE PROC master.dbo.DatabaseReIndex(@Database VARCHAR(100)) AS BEGIN
DECLARE @DbID SMALLINT=DB_ID(@Database)--Get Database ID
DECLARE @I TABLE (IndexTempID INT IDENTITY(1,1),SchemaName NVARCHAR(128),TableName NVARCHAR(128),IndexName NVARCHAR(128),IndexFrag FLOAT)
INSERT INTO @I
EXEC ('USE '+@Database+';
SELECT sch.name,OBJECT_NAME(ind.OBJECT_ID) AS TableName,ind.name IndexName,indexstats.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats('+@DbID+', NULL, NULL, NULL, NULL) indexstats
INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id AND ind.index_id = indexstats.index_id
INNER JOIN sys.objects obj on obj.object_id=indexstats.object_id
INNER JOIN sys.schemas as sch ON sch.schema_id = obj.schema_id
WHERE indexstats.avg_fragmentation_in_percent > 10 AND indexstats.index_type_desc<>''HEAP''
ORDER BY indexstats.avg_fragmentation_in_percent DESC')--Get index data and fragmentation, set the percentage as high or low as you need
DECLARE @IndexTempID BIGINT=0,@SchemaName NVARCHAR(128),@TableName NVARCHAR(128),@IndexName NVARCHAR(128),@IndexFrag FLOAT
SELECT * FROM @I--View your results, comment out if not needed...
-- Loop through the indexes
WHILE @IndexTempID IS NOT NULL BEGIN
    SELECT @SchemaName=SchemaName,@TableName=TableName,@IndexName=IndexName,@IndexFrag=IndexFrag FROM @I WHERE IndexTempID=@IndexTempID
    IF @IndexName IS NOT NULL AND @SchemaName IS NOT NULL AND @TableName IS NOT NULL BEGIN
    IF @IndexFrag<30. BEGIN--Low fragmentation can use re-organise, set at 30 as per most articles
    PRINT 'USE '+@Database+'; ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @TableName + N' REORGANIZE'
    EXEC('USE '+@Database+'; ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @TableName + N' REORGANIZE')
    END
    ELSE BEGIN--High fragmentation needs re-build
    PRINT 'USE '+@Database+'; ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @TableName + N' REBUILD'
    EXEC('USE '+@Database+'; ALTER INDEX ' + @IndexName + N' ON ' + @SchemaName + N'.' + @TableName + N' REBUILD')
    END
    END
    SET @IndexTempID=(SELECT MIN(IndexTempID) FROM @I WHERE IndexTempID>@IndexTempID)
END
END
GO
