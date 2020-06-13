
## RStoolKit Results: High CPU queries (>80 Percent)

The STL_QUERY_METRICS system table will track the CPU consumed by each query. Its an useful table to find the queries that are consuming high CPU. The `query_cpu_usage_percent` column will tell the CPU consumption. But unfortunately it'll tell the CPU usage per step. (Segment, Stage, Step are the query execution levels in redshift). But we can consider the Max CPU usage step.

## Find High CPU consuming queries:

```sql
WITH cte 
     AS (SELECT query, 
                service_class, 
                Max(query_cpu_usage_percent) AS cpu 
         FROM   svl_query_metrics 
         WHERE  query_execution_time > 60 
                AND query_cpu_usage_percent IS NOT NULL 
                AND (service_class BETWEEN 6 AND 13 or service_class >100)
                AND query_cpu_usage_percent > 80 
         GROUP  BY query, 
                   service_class) 
SELECT a.query, 
       a.cpu, 
       a.service_class, 
       b.querytxt, 
       ( endtime - starttime ) AS exec_time 
FROM   cte a 
       join stl_query b 
         ON a.query = b.query 
ORDER  BY cpu DESC;

-- Sometime Vacuum may consume more CPU, so if you want to skip the vacuum part run the below query
SELECT query, 
       Max(query_cpu_usage_percent) cpu 
FROM   svl_query_metrics 
WHERE  query_execution_time > 60 
       AND query_cpu_usage_percent IS NOT NULL 
       AND (service_class BETWEEN 6 AND 13 or service_class >100)
       AND query_cpu_usage_percent > 80 
       AND query NOT IN(SELECT query 
                        FROM   stl_query 
                        WHERE  querytxt NOT LIKE 'Vacuum' 
                                OR querytxt NOT LIKE 'vacuum') 
GROUP  BY query

```

**Why Im using some weird where conditions?**

1.  query_cpu_usage_percent IS NOT NULL 
2. service_class BETWEEN 6 AND 13 or service_class >100
3. query_execution_time 

If you take a look at this table you can see the query_cpu_usage_percent is NULL, then the service class will be SQA service class. Or the query is a Vacuum query. And some times the CPU usage goes more than 100% like 400% or 2000% like this. Then I reached our AWS to understand this.

> *You mentioned that the CPU utilization was greater than 100% for some queries. I did some research on this and turns out that due to some sampling errors while calculating query_cpu_usage_percent, short queries which run in less than 10 sec appear to have CPU utilization greater than 100%. Unfortunately, due to the way we calculate CPU%, we do not have a fix for this currently, so the only option is to disregard those queries which has CPU% greater than 100% or have query duration less than 10 sec. The above query also has a duration_s column to get the query duration.*

## How to fix the problem:

It is mostly from query optimization side, but you still you can do the following best practices to get some more performance and avoid unnecessary CPU spike. 

1. Sort Keys are important.
2. Choose the right dist key, if you are not sure then use auto dist style.
3. Run vacuum and analyze frequently.  
4. Tune the WLM settings, if you are not sure about this then go for Auto WLM.
5. Use concurrency scaling if need.
6. Find the Most frequent alert from the STL_ALERT_EVENT_LOG table.

Run the below query to find exactly which step in that query consumed more space. 

```sql
SELECT query, 
       segment, 
       step, 
       Max(query_cpu_usage_percent) as cpu 
FROM   svl_query_metrics 
WHERE  query_cpu_usage_percent IS NOT NULL 
       AND (service_class BETWEEN 6 AND 13 or service_class >100)
       AND query_cpu_usage_percent > 80 
       AND ( segment <> 0 
             AND step <> 0 ) 
GROUP  BY query, 
          segment, 
          step
order by cpu desc;
```

## External Links:

1. [svl_query_metrics - Documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_SVL_QUERY_METRICS.html) 
2. [RedShift table design - Playbook](https://aws.amazon.com/blogs/big-data/amazon-redshift-engineerings-advanced-table-design-playbook-preamble-prerequisites-and-prioritization/)
3. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
4. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)
5. [STL_ALERT_EVENT_LOG - documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_ALERT_EVENT_LOG.html) 
6. [Concurrency Scaling in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/concurrency-scaling.html)