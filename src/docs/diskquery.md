
## RStoolKit Results: Disk Based queries

Genially all the relation databases will perform all the process like Filtering, Join, Order by, Group by and etc inside the memory. RedShift also will work in the same way. But the memory allocation for a query is defined by the Workload management. If the memory is not enough then RedShift will perform the operations on the Disk. Sometimes if you are doing some aggregations like SUM() with some join and order by on a few larger tables they can eat more space on your cluster's disk. 

## RStoolKit Results: Max temp space used by queries

Temp spaces are nothing but the disk based queries only.

> **Pro Tip:** [A detailed blog post](https://thedataguy.in/disk-based-query-in-redshift/) about disk based queries where it can take more than 3TB for temp tables.

## Find the disk based queries:

```sql
-- Get the disk based queries information for last 2 days
SELECT q.query, 
       q.endtime - q.starttime             AS duration, 
       SUM(( bytes ) / 1024 / 1024 / 1024) AS GigaBytes, 
       aborted, 
       q.querytxt 
FROM   stl_query q 
       join svl_query_summary qs 
         ON qs.query = q.query 
WHERE  qs.is_diskbased = 't' 
       AND q.starttime BETWEEN SYSDATE - 2 AND SYSDATE 
GROUP  BY q.query, 
          q.querytxt, 
          duration, 
          aborted 
ORDER  BY gigabytes DESC
```

## How to fix them:

We don't have much options here. 

- Give enough memory for all the sessions. This can achieved via better work load management settings.
- Optimize your queries.
- Kill the Queries that are consuming more then N blocks(1 block is 1MB) via query monitoring rules.

## External Links:

1. [A case study - Disk based queries are like monsters](https://thedataguy.in/disk-based-query-in-redshift/)
2. [RedShift QMR Rules](https://docs.aws.amazon.com/redshift/latest/dg/cm-c-wlm-query-monitoring-rules.html)