
## RStoolKit Result: WLM queue wait time > 1min

If you are using Manul WLM or Auto WLM, the number of slots are occupied then the rest of the connections needs to be wait until it'll get a slot. 1 to 2 mins are acceptable, but well tunned WLM can give better formance. 

> **More concurrency + Less memory = More queue + Poor performance**

![/src/img/queuewait.png](/src/img/queuewait.png)

## Find the queries with high wait time

```sql
select
	a.service_class,
	a.query,
	b.querytxt,
	b.starttime,
	b.endtime,
	a.total_queue_time / 1000000 as total_queue_time,
  a.total_exec_time,
  a.query_priority
FROM
	stl_wlm_query a
join stl_query b on
	a.query = b.query
WHERE
	a.total_queue_time / 1000000 > 60;
```

## How to fix this problem:

This issue can be solved by optimizing your WLM settings. 

- Find wich queue has more waittiime.
- Analyze the user who took long time to execute the query.
- If possible setup a QMR rule to kill the long running query/Log it and tune later.
- If your workload is standard (Like morning ETL, then BI queries, evening Maintenance) then you can try the Auto WLM.
- If you are not sure how to properly allocate resources for the manual WLM, then go for AutoWLM. But it needs some time to understand the usage patten.
- If you know your workload very well, then use manual WLM.
    - Create 2 or 3 Slots.
    - Don't allocate more than 15 concurrency for a slot. Because less slots + High memory will help the queries to run faster.
    - Enable Shot query accelarator(Dynamic or choose <20sec)
    - If you want to playaround with Dynamic WLM(change the concurrency and memory allocation)
    - Still if you have the issue, then use RedShift concurrency Scaling.

## Some trobleshooting queries:

Find average query waiting time and execution time:

```sql
-- Credit AWS
select
	service_class as svc_class,
	count(*),
	avg(datediff(microseconds, queue_start_time, queue_end_time)) as avg_queue_time,
	avg(datediff(microseconds, exec_start_time, exec_end_time )) as avg_exec_time
from
	stl_wlm_query
where
	service_class > 4
group by
	service_class
order by
	service_class;
```

Find the maximum query waiting time and execution time:

```sql
select
	service_class as svc_class,
	count(*),
	max(datediff(microseconds, queue_start_time, queue_end_time)) as max_queue_time,
	max(datediff(microseconds, exec_start_time, exec_end_time )) as max_exec_time
from
	stl_wlm_query
where
	svc_class > 5
group by
	service_class
order by
	service_class;
```

Find the average queue wait time per user

```sql
with cte as(
select
	a.service_class,
	b.usename,
	a.total_queue_time / 1000000 as total_queue_time
FROM
	stl_wlm_query a
join pg_user b on
	a.userid = b.usesysid
where
	a.service_class >= 6
	and a.total_queue_time / 1000000 >0 )
select
	service_class,
	usename,
	avg(total_queue_time)
from
	cte
group by
	service_class,
	usename
order by
	service_class,
	usename
```

## External Links:

1. [STL_WLM_QUERY](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_WLM_QUERY.html)
2. [wlm_apex - RedShift admin script](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/wlm_apex.sql)
3. [wlm_apex_hourly - RedShift admin script](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/wlm_apex_hourly.sql)
4. [Admin View to Find hourly trend - v_check_wlm_query_trend_hourly](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminViews/v_check_wlm_query_trend_hourly.sql)
5. [Optimizing WLM](https://www.intermix.io/blog/4-simple-steps-to-set-up-your-wlm-in-amazon-redshift-the-right-way/)