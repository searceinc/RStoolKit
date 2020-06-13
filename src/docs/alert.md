## RStoolKit Results: Tables with high number of alerts

RedShift will log the table names into STL_ALERT_EVENT_LOG tables when query optimizer identifies conditions that might indicate performance issues. This table is only visible to the super user. Use can see the following alerts.

- Missing statistics
- Nested loop
- Very selective filter
- Excessive ghost rows
- Large distribution
- Large broadcast
- Serial execution

## RStoolKit Results: Most frequent Alert (> 500 times)

This particular health check part will be notifying you that what are all the most frequent alerts. 

## Find more frequent alert:

```sql
select
	Trim(Split_part(event, ':', 1)) alert,
	count(*) as count
from
	stl_alert_event_log
group by
	alert
order by
	count desc;
```

## List all tables with their alerts:

```sql
with cte as (
SELECT
	a."schema",
	Trim(s.perm_table_name) AS table,
	Trim(Split_part(l.event, ':', 1)) AS event
FROM
	stl_alert_event_log AS l
left join stl_scan AS s ON
	s.query = l.query
	AND s.slice = l.slice
	AND s.segment = l.segment
join pg_catalog.svv_table_info a on
	s.tbl = a.table_id
WHERE
	l.userid > 1
	AND l.event_time >= Dateadd(day,
	-7,
	Getdate())
	AND s.perm_table_name NOT LIKE 'volt_tt%'
	AND s.perm_table_name NOT LIKE 'Internal Worktable'
GROUP BY
	1,
	2,
	3)
select
	"schema",
	"table",
	count(event)as total_alert,
	Listagg(event,
	' ,')
from
	cte
group by
	"schema",
	"table"
order by
	total_alert desc
```

## How to fix this problem:

There is no solution to fix these alert until you tune the query, but at least the able queries will help you to understand what tables are getting more alerts.

## External Links:

1. [STL_ALERT_EVENT_LOG - documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_ALERT_EVENT_LOG.html)