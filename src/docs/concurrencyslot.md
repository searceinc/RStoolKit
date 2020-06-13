
## RStoolKit Result: Max concurrency for a slot

RedShift has this hard limit of using the number of concurrency slots. It allow upto 50 concurrent queries within that 1 slot will be allocated to Super user queue. So totally 49 slots we'll get. If you are using Auto WLM then this concurrency will be taken care. But with manual WLM, we have allocate the right concurrency. 

## Find the concurrency for each queue:

```sql
-- Not applicable for Auto WLM
select
	service_class ,
	name,
	num_query_tasks
FROM
	stv_wlm_service_class_config
WHERE
	service_class BETWEEN 6 AND 13;
```

## How to fix this problem?

It is highly recommended to use upto 15 concurrency for a queue. Because the less number of slots will get more memory. So your queries will run faster and you'll not get much queue wait time. 

**From AWS Docs,**

If your workload requires more than 15 queries to run in parallel, then we recommend enabling concurrency scaling. This is because increasing query slot count above 15 might create contention for system resources and limit the overall throughput of a single cluster. With concurrency scaling, you can run hundreds of queries in parallel up to a configured number of concurrency scaling clusters. The number of concurrency scaling clusters that can be used is controlled by [max_concurrency_scaling_clusters](https://docs.aws.amazon.com/redshift/latest/dg/r_max_concurrency_scaling_clusters.html).

### Enable Short Query Accelerator:

SQA is a sperate queue in RedShift where redshift will automatically identify the queries execution time from some internal algorithm and query plan. If the query matches the execution time with SQA query time, then Redshift will move that particular query to SQA queue. 

## External Links:

1. [Redshift SQA](https://docs.aws.amazon.com/redshift/latest/dg/wlm-short-query-acceleration.html) 
2. [Optimize WLM](https://www.intermix.io/blog/4-simple-steps-to-set-up-your-wlm-in-amazon-redshift-the-right-way/)