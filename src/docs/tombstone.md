
## RStoolKit Result: Tables with tombstone blocks

Tombstone blocks are generated when a WRITE transaction to an Amazon Redshift table occurs and there is a concurrent Read. Amazon Redshift keeps the blocks before the write operation to keep a concurrent Read operation consistent. Amazon Redshift blocks can’t be changed. Every Insert, Update or Delete action creates a new set of blocks, marking the old blocks as tombstoned. – *AWS Doc*

> **Pro Tip**: Here is the more [detailed Blog post](https://thedataguy.in/redshift-tombstone-blocks-visual-explanation/) about the tombstone block with visual explanation. 
![](/src/img/RedShift-Tombstone-Blocks-a-visual-explanation6.JPG)
## Find the tombstone blocks for all the tables:

```sql
-- Credits: AWS: Find the number of tombstones  blocks
SELECT Trim(name) AS tablename, 
       Count(CASE 
               WHEN tombstone > 0 THEN 1 
               ELSE NULL 
             END) AS tombstones 
FROM   svv_diskusage 
GROUP  BY 1 
HAVING Count(CASE 
               WHEN tombstone > 0 THEN 1 
               ELSE NULL 
             END) > 0 
ORDER  BY 2 DESC;

-- Credits: AWS: Find when these blocks are added
SELECT node, 
       Date_trunc('h', endtime) AS endtime, 
       Min(tombstonedblocks)    min_tombstonedblocks, 
       Max(tombstonedblocks)    AS max_tombstonedblocks 
FROM   stl_commit_stats 
WHERE  tombstonedblocks > (SELECT 0.1 * SUM(capacity) AS disksize 
                           FROM   stv_partitions 
                           WHERE  host = owner 
                                  AND host = 0) 
GROUP  BY 1, 
          2 
ORDER  BY 2, 
          1;
```

## How to fix this problem:

Tombstone blocks can be removed by running the vacuum FULL or DELETE ONLY. It always recommended to schedule the vacuum process, so you don't need to worry about this. Even RedShift also will do auto vacuum, when your cluster's load is less. 

```sql
VACUUM [ FULL | SORT ONLY | DELETE ONLY | REINDEX ] 
[ [ table_name ] [ TO threshold PERCENT ] [ BOOST ] ]
```

## External Links:

1. [Vacuum options in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/r_VACUUM_command.html)
2. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
3. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)
4. [Tombstone Blocks - A visual explanation](https://thedataguy.in/redshift-tombstone-blocks-visual-explanation/)