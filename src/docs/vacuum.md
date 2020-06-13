
## RStoolKit Result: Tables never performed vacuum

If you delete or update any rows, in RedShift these rows are marked for deletion. Basically its a soft delete. Vacuum will help us to clean these ghost rows. If you didn't run vacuum or Redshift also didn't perform any auto vacuum, then those tables will consume more space and affect the query performance. 

## RStoolKit Result: Table vacuum older than 5 days

You may schedule the vacuum process or RedShift also will trigger the vacuum. But if the cluster is busy then the auto vacuum will not trigger. So some busy tables may not vacuumed recently. This will also lead to performance issues. 

## Find the tables without vacuum:

All the vacuum activities are tracked in STL_VACUUM system table. So based on this table, we can collect the table names. But unfortunately, this table will not contains the historical data. 

```sql
select
	"schema",
	"table"
FROM
	pg_catalog.svv_table_info
WHERE
	table_id NOT IN (
	SELECT
		table_id
	FROM
		stl_vacuum);
```

## Find tables with vacuum performed older than 5 days:

```sql
WITH cte AS (
SELECT
	table_id,
	Max(eventtime)AS eventtime
FROM
	stl_vacuum
WHERE
	status LIKE '%Finished%'
GROUP BY
	table_id )
SELECT
	"schema",
	"table"
FROM
	pg_catalog.svv_table_info
join cte ON
	svv_table_info.table_id = cte.table_id
WHERE
	cte.eventtime >= current_date - interval '5 day';
```

## How to fix this problem:

Running Vacuum on a scheduled basis is the only way to remove the right solution for this. Anyhow RedShift also will run the vacuum process automatically when there is no load on the cluster. But if your tables are just append only then you may not need to run the vacuum FULL instead run the SORT ONLY.

- Run the vacuum FULL or Delete to remove the ghost rows.

```sql
VACUUM [ FULL | SORT ONLY | DELETE ONLY | REINDEX ] 
[ [ table_name ] [ TO threshold PERCENT ] [ BOOST ] ]
```

- Also run the analyze once the Vacuum is done.

```sql
ANALYZE [ VERBOSE ]
[ [ table_name [ ( column_name [, ...] ) ] ]
[ PREDICATE COLUMNS | ALL  COLUMNS ]
```

## External Links:

1. [Vacuum options in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/r_VACUUM_command.html)
2. [Analyze in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/r_ANALYZE.html)
3. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
4. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)