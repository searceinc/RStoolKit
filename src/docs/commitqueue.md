## RStoolKit Result: WLM commit queue wait

This is nothing but its again the wait time during the commit. In most of the clusters, this doesn't have a much wait time. But still more wait time on commit is bad for your performance. It'll increase the overall execution time.

## Find the commit queue wait time:

```sql
SELECT
	a.xid,
	Datediff(seconds,
	a.startqueue,
	a.startwork) AS queue_time,
	b.query,
	b.querytxt
FROM
	stl_commit_stats a
join stl_query b on
	a.xid = b.xid
WHERE
	startqueue >= Dateadd(day,
	-2,
	current_date)
```

## How to fix this problem?

If the wait time is more then 3 mins, then it should be fixed. First we need to figure out why it is slow. RedShift's each commit will go to the commit queue and then commit. If the 1st transaction is waiting on the queue, then the upcoming transactions also will put on the queue. Once the 1st transaction has been committed,then the commit queue will process the next transactions. Avoid single transaction commits will improve its performance. Or batch your small inserts. Run the above query to find out the most top queries that has more wait time, then tune them.

## External Links:

1. [How to solve a long commit queue wait - A discussion from AWS Forum](https://forums.aws.amazon.com/thread.jspa?threadID=226329)
2. [Why insert performance is slow on RedShift - StackOverflow](https://stackoverflow.com/questions/16485425/aws-redshift-jdbc-insert-performance) 
3. [RedShift top 10 performance tuning tips - See #8](https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-techniques-for-amazon-redshift/)