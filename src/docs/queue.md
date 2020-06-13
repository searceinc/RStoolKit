
## RStoolKit Result: Number of WLM queue

If you are using a manual WLM, then you are limited with 8 custom user defined queues. Also we RedShift allows only 50 concurrent queries. So your 8 queue should share the 50 concurrent slots. (But 1 will be used for Super user queue). 

## Find the number of queues and their concurrency:

```sql
-- Not applicable for Auto WLM
select
	service_class ,
	name,
	num_query_tasks,
	query_working_mem
FROM
	stv_wlm_service_class_config
WHERE
	service_class BETWEEN 6 AND 13;
```

If it is returns a single row, then you are using the default queue. This is also a bad practice.

## How to fix this problem:

There is no thumb rule to have the X number of queues. But generally we can optimize our workload within 2 or 3 queues. Because

> Less queues with more concurrency + memory = Better individual queries performance.

But some best practices: 

- Use upto 3 slots if you know your workload.
- Don't use more than 15 slots per queue.
- If you don't know your workload, then switch to Auto WLM.

## External Links:

1. [WLM system tables and views](https://docs.aws.amazon.com/redshift/latest/dg/cm-c-wlm-system-tables-and-views.html)
2. [Optimizing WLM](https://www.intermix.io/blog/4-simple-steps-to-set-up-your-wlm-in-amazon-redshift-the-right-way/)