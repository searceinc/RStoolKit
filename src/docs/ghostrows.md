
## RStoolKit Results: Ghost rows

RedShift is built on top of PostgreSQL database. In PostgreSQL you may familiar with the term Dead Tuples/Rows. If you delete any row or update any row that particular row is marked for delete. In Redshift update means delete the current row and insert the new row with the updated values. This old row is marked as delete. These rows are called as Ghost rows. 

## Find Ghost rows:

Use the following query to find the ghost rows for all the tables.  You can refer **[this link](https://thedataguy.in/find-ghost-rows-redshift/)** to get more detailed information about the ghost rows. 
[https://thedataguy.in/find-ghost-rows-redshift/](https://thedataguy.in/find-ghost-rows-redshift/)
```sql
with cte as (
select
	table_id,
	status,
	eventtime
from
	stl_vacuum
where
	( status = 'Started'
	or status like '%Started Delete Only%'
	or status like '%Finished%') ),
result_set as (
select
	table_id ,
	max(a.eventtime)as vacuum_timestamp
from
	cte a
where
	a.status like '%Finished%'
group by
	table_id ) ,
raw_gh as(
select
	query,
	tbl,
	perm_table_name ,
	segment,
	sum(a.rows_pre_filter) as rows_pre_filter ,
	sum(a.rows_pre_user_filter) as rows_pre_user_filter ,
	sum(a.rows_pre_filter-a.rows_pre_user_filter)as ghrows
from
	stl_scan a
LEFT JOIN result_set c on
	a.tbl = c.table_id
where
	a.starttime > coalesce(c.vacuum_timestamp, CURRENT_TIMESTAMP - INTERVAL '5 days')
	and perm_table_name not in ('Internal Worktable',
	'S3')
	and is_rlf_scan = 'f'
	and (a.rows_pre_filter <> 0
	and a.rows_pre_user_filter <> 0 )
group by
	segment,
	query,
	tbl,
	perm_table_name ),
ran as(
select
	*,
	dense_rank() over (partition by tbl
order by
	query desc,
	segment desc) as rnk
from
	raw_gh )
select
	b."schema",
	b."table",
	sum(rows_pre_filter) as total_rows,
	sum(rows_pre_user_filter) as valid_rows,
	sum(ghrows) as ghost_rows
from
	ran a
join pg_catalog.svv_table_info b on
	a.tbl = b.table_id
where
	rnk = 1 
group by
	"schema" ,
	"table";
```

## How to fix this problem:

Vacuum is the only way to remove the ghost rows from the tables. Anyhow RedShift also will run the vacuum process automatically when there is no load on the cluster. 

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