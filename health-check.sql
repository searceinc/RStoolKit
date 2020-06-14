-- RedShift HealthCheck ToolKit
-- Version 1.0
-- Developed by Searce Data team
-- Updates: https://thedataguy.in/

-- Disable cache for this session
SET enable_result_cache_for_session = OFF;

-- Drop the temp table for storing the checklist results
DROP TABLE IF EXISTS rstk_metric_result;

-- Create temp table for storing the checklist results
create temp table rstk_metric_result 
  ( 
     priority int,
     category varchar(50),
     finding  varchar(300), 
     details  varchar(65000),
     url      varchar(300), 
     value    varchar(1000),
     checkid  int
  ); 

-- Insert information row
INSERT INTO rstk_metric_result 
VALUES      (0, 
             current_timestamp, 
             'RedShift HealthCheck ToolKit', 
			 'To get help or add you own contribution join us at https://github.com/BhuviTheDataGuy/RedShift-ToolKit', 
			 'https://thedataguy.in', 
			 NULL, 
			 NULL); 

-- Tables without sort keys
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 1, 
       'Design', 
       'Tables without sort key', 
       'https://thedataguy.in/rskit/sortkeys', 
       Count(*) 
FROM   pg_catalog.svv_table_info 
WHERE  sortkey1 IS NULL
	   AND "schema" not like 'pg_temp%'; 

-- Sort key column compressed
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 2, 
       'Design', 
       'Sort key column compressed', 
       'https://thedataguy.in/rskit/sortkeycompress', 
       Count(*) 
FROM   pg_catalog.svv_table_info 
WHERE  sortkey1 IS NOT NULL 
       AND sortkey1_enc <> 'none'
       AND "schema" not like 'pg_temp%'; 

-- Sort key skew > 4
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 3, 
       'Design', 
       'Sort key skew', 
       'https://thedataguy.in/rskit/sortkeyskew', 
       Count(*) 
FROM   svv_table_info 
WHERE  sortkey1 IS NOT NULL 
       AND skew_sortkey1 > 4
       AND "schema" not like 'pg_temp%'; 

-- Tables with high Skew
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 4, 
       'Design', 
       'Tables with high Skew', 
       'https://thedataguy.in/rskit/tableskew', 
       Count(*) 
FROM   svv_table_info 
WHERE  diststyle LIKE 'KEY%' 
       AND skew_rows > 3
       AND "schema" not like 'pg_temp%';  

-- Tables without compression
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 5, 
       'Design', 
       'Tables without compression', 
       'https://thedataguy.in/rskit/tablecompress', 
       Count(*) 
FROM   pg_catalog.svv_table_info 
WHERE  encoded <> 'Y'
	   AND "schema" not like 'pg_temp%'; 

-- WLM queue wait time > 1min
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 6, 
       'WLM', 
       'WLM queue wait time', 
       'https://thedataguy.in/rskit/queuewait', 
       Count(*) 
FROM   stl_wlm_query w 
WHERE  w.total_queue_time / 1000000 > 60; 

-- WLM max connection hit
-- Credit: This query is taken from AWS RedShit Utilities with some changes to boost up performance on single node cluster.
-- Script name: wlm_apex_hourly
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
WITH generate_dt_series AS 
( 
       SELECT SYSDATE - (n * interval '1 minute') AS dt 
       FROM   ( 
                     SELECT row_number() over () AS n 
                     FROM   stl_scan limit 10080)), apex AS 
( 
         SELECT   iq.dt, 
                  iq.service_class, 
                  iq.num_query_tasks, 
                  count(iq.slot_count) AS service_class_queries, 
                  SUM(iq.slot_count)   AS service_class_slots 
         FROM     ( 
                         SELECT gds.dt, 
                                wq.service_class, 
                                wscc.num_query_tasks, 
                                wq.slot_count 
                         FROM   stl_wlm_query wq 
                         join   stv_wlm_service_class_config wscc 
                         ON     ( 
                                       wscc.service_class = wq.service_class 
                                AND    wscc.service_class > 4) 
                         join   generate_dt_series gds 
                         ON     ( 
                                       wq.service_class_start_time <= gds.dt 
                                AND    wq.service_class_end_time > gds.dt) 
                         WHERE  wq.userid > 1 
                         AND    wq.service_class > 4) iq 
         GROUP BY iq.dt, 
                  iq.service_class, 
                  iq.num_query_tasks), maxes AS 
( 
         SELECT   apex.service_class, 
                  trunc(apex.dt)           AS d, 
                  date_part(h,apex.dt)     AS dt_h, 
                  max(service_class_slots)    max_service_class_slots 
         FROM     apex 
         GROUP BY apex.service_class, 
                  apex.dt, 
                  date_part(h,apex.dt)) , final_result AS 
( 
         SELECT   apex.service_class, 
                  apex.num_query_tasks AS max_wlm_concurrency, 
                  maxes.d              AS day, 
                  maxes.dt_h 
                           || ':00 - ' 
                           || maxes.dt_h 
                           || ':59'             AS hour, 
                  max(apex.service_class_slots) AS max_service_class_slots 
         FROM     apex 
         join     maxes 
         ON       ( 
                           apex.service_class = maxes.service_class 
                  AND      apex.service_class_slots = maxes.max_service_class_slots) 
         GROUP BY apex.service_class, 
                  apex.num_query_tasks, 
                  maxes.d, 
                  maxes.dt_h 
         ORDER BY apex.service_class, 
                  maxes.d, 
                  maxes.dt_h) 
SELECT 7, 
       'WLM', 
       'WLM max connection hit', 
       'https://thedataguy.in/rskit/highconnection', 
       max(max_service_class_slots) AS maxv 
FROM   final_result 
WHERE  service_class >=6;

-- Number of WLM queue
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 8, 
       'WLM', 
       'Number of WLM queue', 
       'https://thedataguy.in/rskit/queue', 
       Count(*) 
FROM   stv_wlm_service_class_config 
WHERE  service_class BETWEEN 6 and 13; 

-- Auto WLM enabled
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 9, 
       'WLM', 
       'Auto WLM enabled', 
       'https://thedataguy.in/rskit/autowlm', 
       Count(*) 
FROM   stv_wlm_service_class_config 
WHERE  service_class >= 100; 

-- Max concurrency for a slot
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 10, 
       'WLM', 
       'Max concurrency for a slot', 
       'https://thedataguy.in/rskit/concurrencyslot', 
       Max(num_query_tasks) 
FROM   stv_wlm_service_class_config 
WHERE  service_class BETWEEN 6 AND 13; 

-- WLM commit queue wait 
INSERT INTO rstk_metric_result 
            ( 
                        checkid, 
                        category, 
                        finding, 
                        url, 
                        value 
            ) 
SELECT 11, 
       'WLM', 
       'WLM commit queue wait', 
       'https://thedataguy.in/rskit/commitqueue', 
       Max(queue_time) 
FROM   (SELECT Datediff(seconds, startqueue, startwork) AS queue_time 
        FROM   stl_commit_stats 
        WHERE  startqueue >= Dateadd(day, -7, current_date) 
        ORDER  BY queue_time DESC); 

-- Ghost rows
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
WITH raw_gh AS 
( 
         SELECT   query, 
                  tbl, 
                  perm_table_name , 
                  segment, 
                  SUM(a.rows_pre_filter-a.rows_pre_user_filter)AS ghrows 
         FROM     stl_scan a 
         WHERE    a.starttime > current_timestamp - interval '5 days' 
         and      perm_table_name NOT            IN ('Internal Worktable', 
                                                     'S3') 
         AND      is_rlf_scan = 'f' 
         AND      ( 
                           a.rows_pre_filter <> 0 
                  AND      a.rows_pre_user_filter <> 0 ) 
         GROUP BY SEGMENT, 
                  query, 
                  tbl, 
                  perm_table_name ), ran AS 
( 
         SELECT   *, 
                  dense_rank() over (PARTITION BY tbl ORDER BY query DESC, SEGMENT DESC) AS rnk
         FROM     raw_gh ), final_cte AS 
( 
         SELECT   max(query), 
                  SUM(ghrows)AS ghrows 
         FROM     ran 
         WHERE    rnk = 1 
         GROUP BY tbl) 
SELECT 12, 
       'Vacuum', 
       'Ghost rows', 
       'https://thedataguy.in/rskit/ghostrows', 
       SUM(ghrows) 
FROM   final_cte; 

-- Tables never performed vacuum (based on STL_Vacuum)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 13, 
       'Vacuum', 
       'Tables never performed vacuum', 
       'https://thedataguy.in/rskit/vacuum', 
       count(*) 
        FROM   pg_catalog.svv_table_info 
        WHERE  table_id NOT IN (SELECT table_id 
                                FROM   stl_vacuum); 

-- Table vacuum older than 5 days
INSERT INTO rstk_metric_result 
            ( 
                        checkid, 
                        category, 
                        finding, 
                        url, 
                        value 
            ) 
            WITH cte AS 
            ( 
                     SELECT   table_id, 
                              Max(eventtime)AS eventtime1 
                     FROM     stl_vacuum 
                     WHERE    status LIKE '%Finished%' 
                     GROUP BY table_id 
            ) 
   SELECT 14, 
          'Vacuum', 
          'Table vacuum older than 5 days', 
          'https://thedataguy.in/rskit/vacuum', 
          Count(*) 
   FROM   pg_catalog.svv_table_info 
   join   cte 
   ON     svv_table_info.table_id= cte.table_id 
   WHERE  cte.eventtime1>= current_date - interval '5 day';

-- Tables with tombstone blocks
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
WITH cte 
     AS (SELECT Trim(name) AS tablename, 
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
         ORDER  BY 2 DESC) 
SELECT 15, 
       'Vacuum', 
       'Tables with tombstone blocks', 
       'https://thedataguy.in/rskit/tombstone', 
       Count(tablename) 
FROM   cte;  

-- Tables with missing stats
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 16, 
       'Vacuum', 
       'Tables with missing stats', 
       'https://thedataguy.in/rskit/stats', 
       Count(*) 
FROM   (SELECT plannode 
        FROM   stl_explain 
        WHERE  plannode LIKE '%missing statistics%' 
               AND plannode NOT LIKE '%redshift_auto_health_check_%' 
        GROUP  BY plannode); 

-- Tables with stale stats (> 5 percent)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 17, 
       'Vacuum', 
       'Tables with stale stats', 
       'https://thedataguy.in/rskit/stats', 
       Count(*) 
FROM   svv_table_info 
WHERE  stats_off > 5; 


-- Top sized tables 
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 18, 
       'Table', 
       'Top sized tables', 
       'https://thedataguy.in/rskit/specturm', 
       Count(*) 
FROM   pg_catalog.svv_table_info 
WHERE  pct_used >= 40; 

-- Table with high number of alerts (>3 alerts)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 19, 
       'Table', 
       'Tables with high number of alerts', 
       'https://thedataguy.in/rskit/alert', 
       Count("table") 
FROM   (SELECT "table", 
               Count(*) AS count 
        FROM   (SELECT Trim(s.perm_table_name)           AS table, 
                       Trim(Split_part(l.event, ':', 1)) AS event 
                FROM   stl_alert_event_log AS l 
                       left join stl_scan AS s 
                              ON s.query = l.query 
                                 AND s.slice = l.slice 
                                 AND s.segment = l.segment 
                WHERE  l.userid > 1 
                       AND l.event_time >= Dateadd(day, -7, Getdate()) 
                       AND s.perm_table_name NOT LIKE 'volt_tt%' 
                       AND s.perm_table_name NOT LIKE 'Internal Worktable' 
                GROUP  BY 1, 
                          2) 
        GROUP  BY 1) 
WHERE  count >= 3; 

-- Non scaned Tables (based on STL Scan)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 20, 
       'Table', 
       'Non scaned Tables', 
       'https://thedataguy.in/rskit/unusedtable', 
       Count(*) 
FROM   pg_catalog.svv_table_info 
WHERE  "table" NOT IN (SELECT DISTINCT ( perm_table_name ) 
                       FROM   pg_catalog.stl_scan); 

-- Tables without backup
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 21, 
       'Table', 
       'Tables without backup', 
       'https://thedataguy.in/rskit/nobackup', 
       Count(*) 
FROM   stv_tbl_perm 
WHERE  BACKUP = 0 and temp=0; 

-- Tables with fragmentation
-- Credit: This query is taken from AWS RedShit Utilities
-- Script name: v_fragmentation_info.sql
INSERT INTO rstk_metric_result 
            ( 
                        checkid, 
                        category, 
                        finding, 
                        url, 
                        value 
            ) 
SELECT 22, 
       'Table', 
       'Tables with fragmentation', 
       'https://thedataguy.in/rskit/fragmentation', 
       Count(tablename) 
FROM   ( 
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
                                    Count(*) - Ceil(SUM(num_values) / 130994.0) 
                                    AS 
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
                                             WHEN SUM(capacity) > 200000 THEN 
                                             1024 
                                             ELSE 102.4 
                                           END 
                                    FROM   stv_partitions 
                                    WHERE  host = owner 
                                           AND host = 0 
                                    GROUP  BY host) 
        GROUP  BY 1, 
                  2, 
                  3 
        ORDER  BY 4 DESC);

-- Disk based queries
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 23, 
       'Performance', 
       'Disk based queries', 
       'https://thedataguy.in/rskit/diskquery', 
       Count(*) 
FROM   (SELECT query 
        FROM   svl_query_summary 
        WHERE  is_diskbased = 't' 
        GROUP  BY query); 

-- COPY not optimized 
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 24, 
       'Performance', 
       'COPY not optimized', 
       'https://thedataguy.in/rskit/copy', 
       Count(*) 
FROM   (SELECT Count(*) AS n_files 
        FROM   stl_s3client 
        WHERE  http_method = 'GET' 
               AND query > 0 
               AND transfer_time > 0 
        GROUP  BY query) 
WHERE  n_files % (SELECT Count(slice) 
                  FROM   stv_slices) != 0; 

-- High CPU queries (>80 Percent)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 25, 
       'Performance', 
       'High CPU queries', 
       'https://thedataguy.in/rskit/highcpu', 
       Count(*) 
FROM   (SELECT query, 
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
GROUP  BY query ); 

-- Most frequent Alert (> 500 times)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 26, 
       'Performance', 
       'Most frequent Alert', 
       'https://thedataguy.in/rskit/alert', 
       Listagg(event, ' ,') 
FROM   (SELECT Trim(Split_part(event, ':', 1)) AS event, 
               Count(*) 
        FROM   stl_alert_event_log 
        GROUP  BY 1) 
WHERE  count > 500; 

-- Long running queries (> 30mins)
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 27, 
       'Performance', 
       'Long running queries', 
       'https://thedataguy.in/rskit/slowquery', 
       Count(*) 
FROM   svl_query_metrics 
WHERE  query_execution_time >= 1800; 

-- Max temp space used by queries
INSERT INTO rstk_metric_result 
            (checkid, 
             category, 
             finding, 
             url, 
             value) 
SELECT 28, 
       'Performance', 
       'Max temp space used by queries', 
       'https://thedataguy.in/rskit/diskquery', 
       Max(gigabytes) 
FROM   (SELECT SUM(( bytes ) / 1024 / 1024 / 1024) AS GigaBytes 
        FROM   stl_query q 
               join svl_query_summary qs 
                 ON qs.query = q.query 
        WHERE  qs.is_diskbased = 't' 
               AND q.starttime BETWEEN SYSDATE - 7 AND SYSDATE 
        GROUP  BY q.query); 
-- -------------------------------------
-- Adding the description and priority
-- -------------------------------------
-- Tables without sort keys
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN 'There are ' 
                                                  || value 
                                                  || 
' tables without sortkeys. This will result in scanning of all blocks for even range restricted predicates' 
  ELSE 'Awesome, all of your tables having sort keys!!!' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 10 THEN 2 
  WHEN Cast(value AS INT) =0 then 3
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 1) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Sort key column compressed
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN 'There are ' 
                                                  || value 
                                                  || 
' tables where sort key columns are compressed, this may lead to a slight performance degradation'
  ELSE 'Awesome, none of your sort key columns are compressed' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 10 THEN 2 
  WHEN Cast(value AS INT) =0 then 3
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 2) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Sort key skew > 4
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN value 
                                                  || 
' tables sort keys are skewed which indicates that you have to uncompress the sort key column or these columns may not be the right candidate for the sort keys. '
  ELSE 'Your sort keys are does not have any skew.' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 10 THEN 2 
  WHEN Cast(value AS INT) =0 then 3
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 3) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables with high Skew
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN value 
                                                  || 
' tables have skew in termns of distribution. This will result in more load on few nodes. Consider changing the dist key if required'
  ELSE 'Seems the table distribution looks good' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 10 THEN 2 
  WHEN Cast(value AS INT) = 0 then 3
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 4) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables without compression
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN value 
                                                  || 
               ' tables are not compressed yet, this is not a good practice and needs to be fixed immediately, please compress all the columns except the sort key' 
                 ELSE 'Good Job!!! All the tables are compressed' 
               END AS details, 
               CASE 
                 WHEN Cast(value AS INT) > 10 THEN 1 
                 WHEN Cast(value AS INT) BETWEEN 1 AND 10 THEN 2 
                 WHEN Cast(value AS INT) =0 then 3
               END AS priority 
        FROM   rstk_metric_result 
        WHERE  checkid = 5) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- WLM queue wait time > 1min
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 180 THEN ' Sometimes your cluster is spending more time on wait on the queue. The max wait time from last 7 days is ' 
                                                    || value 
                                                    || 
               ' seconds. You have to tune your WLM to reduce the wait time.' 
                 WHEN Cast(value AS INT) < 180 THEN 
'We found that the wait time is less than 180  second ('||value||') which is Good. But still consider tuning WLM if need.'
ELSE 'Unknown -  - Your system tables may not have enough data'
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 900 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 180 AND 900 THEN 2 
  WHEN Cast(value AS INT) < 180 then 3
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 6) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- WLM max connection hit
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) BETWEEN 100 AND 400 THEN 
                 ' This cluster hits ' 
                 || value 
                 || 
' as the high number of connections recently. RedShift supports 500 max connections, so please tune your WLM setting to reduce the wait time and boost the queries.'
  WHEN Cast(value AS INT) < 100 THEN 
'Great!!! This cluster never reach 100 connections (only '||value||') at any point of time, But to speed up concurrent queries in a queue, you may tune the WLM settings.'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 300 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 100 AND 300 THEN 2 
  WHEN Cast(value AS INT) < 100 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 7) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Number of WLM queue
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) = 1 THEN 
' You are using Default queue only, its a Red Flag. At least keep minimum 2 Queues to balance the workload'
  WHEN Cast(value AS INT)BETWEEN 2 AND 3 THEN 'OK! you have ' 
                                              || value 
                                              || 
' queues, not bad. Still if you see any waiting process on the queue then tune WLM' 
  WHEN Cast(value AS INT)BETWEEN 3 AND 7 THEN 'OK! you have ' 
                                              || value 
                                              || 
' queues, not bad. But make sure it should to eat much resources. For a generic workload 2 to 3 queues will work fine.'
  WHEN Cast(value AS INT) =0 then 'You are using Auto WLM, so this check is not applicable'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT)= 1 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 3 AND 7 THEN 2 
  WHEN Cast(value AS INT) BETWEEN 2 AND 3 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 8) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Auto WLM enabled
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) = 0 THEN 
' You are using manual WLM, if you are aware about your workload and the manual WLM has more than 2 or 3 queues then may be it will fit. Or just give a try with Auto WLM and let RedShift decide to allocate the resource'
  WHEN Cast(value AS INT) > 0 THEN 
'You have Auto WLM enbled, Good!!! still you are not convinced then switch to Manual WLM and tune the queues properly.'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) = 0 THEN 2 
  WHEN Cast(value AS INT) > 0 THEN 2 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 9) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Max concurrency for a slot
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 20 THEN ' You have allocated' 
                                                   || value 
                                                   || 
' to your queue, generally more concurrey reduce the capacity. We recommed to use the slots between 15 to 20'
  WHEN Cast(value AS INT) BETWEEN 10 AND 20 THEN 'You have ' 
                                                 || value 
                                                 || 
' concurrent slots, Good!!! ' 
  WHEN Cast(value AS INT) < 10 THEN 'You have ' 
                                    || value 
                                    || 
' which is very less, it may allocate more resource per slot, but many sessions will go to waiting state iin the queue. Optimal value is 15 to 20'
  WHEN value IS NULL then 'You are using Auto WLM, so this check is not applicable'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 20 THEN 1 
  WHEN Cast(value AS INT)BETWEEN 10 AND 20 THEN 2 
  WHEN Cast(value AS INT) < 10 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 10) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- WLM commit queue wait 
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 120 THEN 
                 'We found recently the commit was in the waiting queue for ' 
                 || value 
                 || 
' seconds, many reasons for this, but an optimized WLM will make this process much better' 
  WHEN Cast(value AS INT) BETWEEN 60 AND 120 THEN 
  'We found recently the commit was in the waiting queue for ' 
  || value 
  || 
'  seconds, no flags in that. If you feel its a high numnber, then an optimized WLM will make this process much better '
  WHEN Cast(value AS INT) < 60 THEN 'Great!!! the commit wait was ' 
                                    || value 
                                    || ' seconds, this looks good' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 120 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 60 AND 120 THEN 2 
  WHEN Cast(value AS INT) < 60 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 11) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Ghost rows
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 100000 THEN 
' You have more than 100K Ghost rows totally, it is a Red flag, please run vacuum on these tables.'
  WHEN Cast(value AS INT) BETWEEN 1000 AND 100000 THEN 'You have ' 
                                                       || value 
                                                       || 
' Ghost rows(marked for delete), please run vacuum to remove them' 
  WHEN Cast(value AS INT) < 1000 THEN 
'Awesome!!! You have less than 1K Ghost rows(only '||value||'), but frequently running vacuum will help you to clean up the Ghost rows.'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 100000 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1000 AND 100000 THEN 2 
  WHEN Cast(value AS INT) < 1000 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 12) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables never performed vacuum (based on STL_Vacuum)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN 
' This cluster has '||value||' tables never vacuumed(from STL_Vacuum result), It is a RedFlag. Frequently running vacuum will make this count 0 and improve the overall process'
  WHEN Cast(value AS INT)BETWEEN 1 AND 5 THEN 
' This cluster has '||value||' tables where vacuum never run(from STL_Vacuum result), Frequently running vacuum will make this count 0 and improve the overall process'
  WHEN Cast(value AS INT) = 0 THEN 'Good Job!!! all the tables are vacummed' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 13) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Table vacuum older than 5 days
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 10 THEN 
' More than 10 tables did not perform vacuum from past 5 days, we found '||value||' tables. If the does not have any Ghost rows, then ignore this else run the vacuum'
  WHEN Cast(value AS INT)BETWEEN 5 AND 10 THEN 
'You have less than 10 tables where vacuum did not perform from last 5 days, we found '||value||' tables, this is OK, but still frequently running vacuum will make this count 0 and improve the overall process'
  WHEN Cast(value AS INT) = 0 THEN 'Good Job!!! all the tables are vacummed' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 5 AND 10 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 14) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables with tombstone blocks
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN 
' There are '||value||' tables where Tombstone blocks are there. It will spill the disk quickly and it is a Red Flag. Frequently running vacuum will make this count 0 and improve the overall process'
  WHEN Cast(value AS INT)BETWEEN 1 AND 5 THEN 
' There are '||value||' tables where Tombstone blocks are there, Frequently running vacuum will make this count 0 and improve the overall process'
  WHEN Cast(value AS INT) = 0 THEN 'Good Job!!! No Tombstone blocks found' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 15) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables with missing stats
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN ' We found ' 
                                                  || value 
                                                  || 
' tables with missing statistics, It is a main performance bottleneck. Please run Analyze to update the statistics'
  WHEN Cast(value AS INT)BETWEEN 1 AND 5 THEN 
'We found '||value||' tables with missing statistics, it is a less numer. But please run Analyze to update the statistics'
  WHEN Cast(value AS INT) = 0 THEN 
  'Awesome!!! All the tables statistics are upto date' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 16) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables with stale stats (> 5 percent)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN ' We found ' 
                                                  || value 
                                                  || 
' tables with stale statistics (greater than 5 percent), It is a main performance bottleneck. Please run Analyze to update the statistics'
  WHEN Cast(value AS INT)BETWEEN 1 AND 5 THEN 
'You have '||value||'  tables with stale statistics (less than 5 percent), Please run Analyze to update the statistics'
  WHEN Cast(value AS INT) = 0 THEN 
  'Awesome!!! All the tables statistics are upto date' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 17) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Top sized tables
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 2 THEN 
' You have '||value||' tables where the total size of those tables are greter than 40% of the total cluster size. Please consider to use RedShift Spectrum is possible.'
  WHEN Cast(value AS INT)BETWEEN 1 AND 2 THEN 
' You have '||value||' tables where the total size of those tables are greter than 40% of the total cluster size. Please consider to use RedShift Spectrum is possible'
  WHEN Cast(value AS INT) = 0 THEN 
'Nice!!! All the tables are having less than 40% of the usgae from the total size' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 2 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 2 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 18) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Table with high number of alerts (>3 alerts)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN ' We found that there are ' 
                                                  || value 
                                                  || 
' tables that has more than 3 alerts. Please visit stl_alert_event_log table to find those alerts'
  WHEN Cast(value AS INT) BETWEEN 0 AND 5 THEN 
  'Nice!!! Your tables does not have much alerts.' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 19) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Non scaned Tables (based on STL Scan)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 0 THEN ' We found that there are ' 
                                                  || value 
                                                  || 
' tables never scanned(from STL_SCAN results), Please take a look at these tables, if not required then remove them or move to Specturm'
  WHEN Cast(value AS INT) = 0 THEN 'Nice!!! All the tables are active' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 20) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables without backup
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN ' There are ' 
                                                  || value 
                                                  || 
' tables that mentioned as NOBACKUP in DDL, these tables are never backup via snapshot. Please take a look at these tables, if required then remove NO BACKUP flag'
  WHEN Cast(value AS INT) = 0 THEN 'You have ' 
                                   || value 
                                   || 
' tables with NoBackup flag, This looks fine' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 0 THEN 1 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 21) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Tables with fragmentation
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN 'This cluster has ' 
                                                  || value 
                                                  || 
' tables with Fragmentation, Please run vacuum to defrag the tables' 
  WHEN Cast(value AS INT) = 0 THEN 
  'Great!!! We did not find any tables with fragmentation' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
FROM   rstk_metric_result 
WHERE  checkid = 22) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Disk based queries
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 500 THEN 'You have ' 
                                                    || value 
                                                    || 
' disk based queries, this can spill your disk too quickly and gives bad performance. WLM setting can also help you to fix this'
  WHEN Cast(value AS INT) BETWEEN 300 AND 500 THEN 'You have ' 
                                                   || value 
                                                   || 
' disk based queries, Its a less count, but Disk based queries can spill your disk too quickly and gives bad performance. WLM setting can also help you to fix this'
  WHEN Cast(value AS INT) between 1 and 300 THEN 'Not much disk based quries. You have '||value||' quries only' 
  WHEN Cast(value AS INT) = 0 then 'Awesome!!! No disk based quries'
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 500 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 300 AND 500 THEN 2 
  WHEN Cast(value AS INT) < 300 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 23) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- COPY not optimized 
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 5 THEN 'You did the COPY operation ' 
                                                  || value 
                                                  || 
' times without having the correct number for files, Generally  the number of files is a multiple of the number of slices in your cluster'
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 'You did the COPY operation ' 
                                               || value 
                                               || 
' times without having the correct number for files. Its a less number. Generally  the number of files is a multiple of the number of slices in your cluster'
  WHEN Cast(value AS INT) = 0 THEN 'Awesome!!! You files are properlly sized' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 5 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 1 AND 5 THEN 2 
  WHEN Cast(value AS INT) = 0 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 24) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- High CPU queries (>80 Percent)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 10 THEN 'We found that ' 
                                                   || value 
                                                   || 
' queries consumed more than 80% of the CPU. Please take a look at these queries and tune them.'
  WHEN Cast(value AS INT) BETWEEN 5 AND 10 THEN 'We found that ' 
                                                || value 
                                                || 
' queries consumed more than 80% of the CPU. This is OK.' 
  WHEN Cast(value AS INT) < 5 THEN 
  'Awesome!!! You do not have much High CPU consuming queries.' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 5 AND 10 THEN 2 
  WHEN Cast(value AS INT) < 5 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 25) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Most frequent Alert (> 500 times)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
from   ( 
              SELECT checkid, 
                     CASE 
                            WHEN cast(value AS INT) IS NOT NULL THEN 'We found that ' 
                                          || value 
                                          ||' events are occuring too many times (more then 500 times), Its better to take a look at the tables who has these alerts and tune'
                            ELSE 'You do not have much alerts on alert table' 
                     END AS details, 
                     ( 
                            SELECT count(event) 
                            FROM   ( 
                                            SELECT   trim(split_part(event, ':', 1)) AS event, 
                                                     count(*) 
                                            FROM     stl_alert_event_log 
                                            GROUP BY 1) 
                            WHERE  count > 500) AS count, 
                     CASE 
                            WHEN cast(count AS INT) > 10 THEN 1 
                            WHEN cast(count AS INT) BETWEEN 5 AND    10 THEN 2 
                            WHEN cast(count AS INT) < 5 THEN 3 
                     END AS priority 
              FROM   rstk_metric_result 
              WHERE  checkid = 26) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- 	Long running queries (> 30mins)
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 120 THEN 'You have ' 
                                                    || value 
                                                    || 
' queries that runs more than 120 mins, Its a Red Flag, please take a look and tune those queries.'
  WHEN Cast(value AS INT) BETWEEN 30 AND 120 THEN 'You have ' 
                                                  || value 
                                                  || 
' queries that runs from 1Hr to 2Hrs, lease take a look and tune those queries.' 
  WHEN Cast(value AS INT) < 30 THEN 
  'Awesome!!! All of your queries are completed within 30mins' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 300 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 300 AND 100 THEN 2 
  WHEN Cast(value AS INT) < 100 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 27) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Max temp space used by queries
UPDATE rstk_metric_result 
SET    details = sq.details, 
       priority = sq.priority 
FROM   (SELECT checkid, 
               CASE 
                 WHEN Cast(value AS INT) > 10 THEN 
                 'One of your queries consumed ' 
                 || value 
                 || 
' GB of disk space to store the intermediate results. If your cluster is already consumed 70% of the disk, then its a Red Flag. This may lead to spill the disk too quickly.'
  WHEN Cast(value AS INT) BETWEEN 5 AND 10 THEN 'One of your queries consumed ' 
                                                || value 
                                                || 
' GB of disk space to store the intermediate results. This may lead to spill the disk too quickly.'
  WHEN Cast(value AS INT) < 5 THEN 
'Your queries never consumed more than 5Gb to store intermediate results. This seems OK.' 
  ELSE 'Unknown -  - Your system tables may not have enough data' 
END AS details, 
CASE 
  WHEN Cast(value AS INT) > 10 THEN 1 
  WHEN Cast(value AS INT) BETWEEN 5 AND 10 THEN 2 
  WHEN Cast(value AS INT) < 5 THEN 3 
END AS priority 
 FROM   rstk_metric_result 
 WHERE  checkid = 28) sq 
WHERE  rstk_metric_result.checkid = sq.checkid; 

-- Show the result:
SELECT CASE 
         WHEN priority = 1 THEN 10 
         WHEN priority = 2 THEN 50 
         WHEN priority = 3 THEN 200 
         ELSE 0 
       END AS priority, 
       category, 
       finding, 
       details, 
       url 
FROM   rstk_metric_result 
ORDER  BY priority; 
