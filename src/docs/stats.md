
## RStoolKit Results: Tables with missing stats

RedShift is maintaining the statistics for all the tables to generate a better query plan. If the stats are or out of date, then your queries may perform slower then what you expected. 

If table statistics are missing or out of date, you might see the following:

- A warning message in EXPLAIN command results.
- A missing statistics alert event in STL_ALERT_EVENT_LOG. For more information, see [Reviewing query alerts](https://docs.aws.amazon.com/redshift/latest/dg/c-reviewing-query-alerts.html).

## Tables with stale stats (> 5 percent)

This issue is a slight different from the missing stats. Here the table has statistics. But it is out of date. After the stats gathered, if you perform any more deletes and updates then the table's stats need to be updates. Stale statistics can lead to suboptimal query execution plans and long execution times.

## Find the tables with missing stats:

```sql
with cte as (
SELECT
	query,
	trim(replace(replace(plannode, '-', ''), 'Tables missing statistics:', '')) as table_name
FROM
	stl_explain
WHERE
	plannode LIKE '%missing statistics%'
	AND plannode NOT LIKE '%redshift_auto_health_check_%'
GROUP BY
	query,
	plannode
ORDER BY
	2 DESC)
select
	c."schema",
	c."table",
	count(a.table_name)
from
	cte a
join stl_scan b on
	a.query = b.query
	and a.table_name = b.perm_table_name
join pg_catalog.svv_table_info c on
	b.tbl = c.table_id
group by
	"schema",
	"table";
```

## Find the tables with stale stats:

```sql
select
	"schema",
	"table"
FROM
	svv_table_info
WHERE
	stats_off > 5;
```

## How to fix this problem:

To fix this issue, run the ANALYZE query on those tables. 

```sql
ANALYZE [ VERBOSE ]
[ [ table_name [ ( column_name [, ...] ) ] ]
[ PREDICATE COLUMNS | ALL  COLUMNS ]
```

> **Note**: *To reduce processing time and improve overall system performance, Amazon Redshift skips ANALYZE for a table if the percentage of rows that have changed since the last ANALYZE command run is lower than the analyze threshold specified by the analyze_threshold_percent parameter. By default, analyze_threshold_percent is 10. To change analyze_threshold_percent for the current session, execute the SET command. The following example changes analyze_threshold_percent to 20 percent.*

```sql
set analyze_threshold_percent to 0.01;
```

## External Links:

1. [Vacuum options in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/r_VACUUM_command.html)
2. [Analyze in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/r_ANALYZE.html)
3. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
4. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)