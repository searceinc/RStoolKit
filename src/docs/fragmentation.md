
## RStoolKit Results: Tables with fragmentation

Fragmentation in RedShift is nothing but the Ghost rows and unsorted rows. Whenever we did a delete or update the old row will be marked as deleted. When we run the `VACUUM DELETE` then these rows will be permanently removed. But the space removed by the vacuum will be reclaimed, but its now fragmented. Until you run the `VACUUM SORT ONLY` or `VACUUM FULL` this space will not be defragmented. 

![/src/img/fragmentation.png](/src/img/fragmentation.png)

## Find tables with fragmentation:

In RedShift admin views, we have a view to find the fragmentation.

```sql
-- AWS RedShift Admin view
-- https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminViews/v_fragmentation_info.sql

SELECT tbl, 
       tablename, 
       dbname, 
       SUM(t_excess_blks) est_space_gain 
FROM   (SELECT tbl, 
               col, 
               node, 
               tablename, 
               Trim(datname)                  AS dbname, 
               SUM(excess_blks) * ( col + 1 ) AS t_excess_blks 
        FROM   (SELECT tbl, 
                       slice, 
                       col, 
                       Count(*) total_blks 
                FROM   stv_blocklist 
                WHERE  num_values > 0 
                GROUP  BY 1, 
                          2, 
                          3) a 
               join (SELECT tbl, 
                            slice, 
                            Max(col) AS col 
                     FROM   stv_blocklist 
                     GROUP  BY 1, 
                               2) b USING (tbl, slice, col) 
               join (SELECT tbl, 
                            slice, 
                            col, 
                            Count(*) - Ceil(SUM(num_values) / 130994.0) AS 
                            excess_blks 
                     FROM   stv_blocklist 
                     WHERE  num_values > 0 
                            AND num_values < 130994 
                     GROUP  BY 1, 
                               2, 
                               3) c USING (tbl, slice, col) 
               join stv_slices d USING (slice) 
               join (SELECT id, 
                            Trim("name") AS tablename, 
                            db_id 
                     FROM   stv_tbl_perm 
                     WHERE  slice = 0) f 
                 ON b.tbl = f.id 
               join pg_database g 
                 ON f.db_id = g.oid 
        WHERE  excess_blks > 1 
        GROUP  BY 1, 
                  2, 
                  3, 
                  4, 
                  5) 
WHERE  tbl > 1 
       AND t_excess_blks > (SELECT CASE 
                                     WHEN SUM(capacity) > 200000 THEN 1024 
                                     ELSE 102.4 
                                   END 
                            FROM   stv_partitions 
                            WHERE  host = owner 
                                   AND host = 0 
                            GROUP  BY host) 
GROUP  BY 1, 
          2, 
          3 
ORDER  BY 4 DESC;
```

## How to fix this problem:

To fix the table's fragmentation we need to run the Vacuum to reclaim the space. 

Vacuum Full - permanently delete the ghost rows, reclaim the space and sort them all.

```sql
VACUUM [ FULL | SORT ONLY | DELETE ONLY | REINDEX ] 
[ [ table_name ] [ TO threshold PERCENT ] [ BOOST ] ]
```

Also don't forget to run the analyze.

## External Links:

1. [RedShift vacuum](https://docs.aws.amazon.com/redshift/latest/dg/r_VACUUM_command.html)
2. [Get the ghost rows for all the tables](https://thedataguy.in/find-ghost-rows-redshift/)
3. [RedShift tombstone block](https://thedataguy.in/redshift-tombstone-blocks-visual-explanation/)
4. [RedShift analyze](https://docs.aws.amazon.com/redshift/latest/dg/r_ANALYZE.html)
5. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
6. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)