/* Show indexes to rebuilds */
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
