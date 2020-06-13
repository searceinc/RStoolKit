
## RStoolKit Results: Long running queries (> 30mins)

This is a new to you. Its just telling the queries are running more than 30mins.

## Find the long running queries:

```sql
select
	a.query,
	a.service_class,
	a.query_execution_time,
	a.query_queue_time,
	case
		when b.concurrency_scaling_status = 1 then 'Ran on a concurrency scaling cluster'
		else 'Ran on the main cluster' end as concurrency_scaling_status,
		b.querytxt
	from
		SVL_QUERY_METRICS a
	join stl_query b on
		a.query = b.query
	where
		a.query_execution_time>1800
```

## How to fix the problem:

This will be solved by optimizing your queries only. But still you can solve many long running queries if you have right table design in place. 

1. Sort Keys are important.
2. Choose the right dist key, if you are not sure then use auto dist style.
3. Run vacuum and analyze frequently.  
4. Tune the WLM settings, if you are not sure about this then go for Auto WLM.
5. Use concurrency scaling if need.
6. Find the Most frequent alert from the STL_ALERT_EVENT_LOG table.

Run the below query to find exactly which step in that query consumed more space. 

# External Links:

1. [svl_query_metrics - Documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_SVL_QUERY_METRICS.html) 
2. [RedShift table design - Playbook](https://aws.amazon.com/blogs/big-data/amazon-redshift-engineerings-advanced-table-design-playbook-preamble-prerequisites-and-prioritization/)
3. [RedShift vacuum Utility - Python Based](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)
4. [Automate Vacuum Analyze Utility - Shell based with more control](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)
5. [STL_ALERT_EVENT_LOG - documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_ALERT_EVENT_LOG.html) 
6. [Concurrency Scaling in RedShift](https://docs.aws.amazon.com/redshift/latest/dg/concurrency-scaling.html)