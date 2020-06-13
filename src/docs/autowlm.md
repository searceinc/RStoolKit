
## RStoolKit Result: Auto WLM enabled

When you enable the Auto WLM, then the concurrency slot and the memory allocation for a queue will be defined by RedShift itself. Its using some machine learning algorithm to predict the values for the queue. 

## Auto WLM is good or Bad?

It is an amazing feature to reduce the Admin workload. But still many of us thinking to use the Auto WLM. Whether it is good or bad, it is completely depends on your workload. It may not fit for all of them. So our recommendation is if you know your workload and which user needs more connection and more resources then just simply go for the Manual WLM. If your workload is standard like night time ETL, Morning to evening BI queries then evening some maintenance like vacuum. In this case we know the workload pattern, so its easy to allocate tell when we need more connection and memory. So here Auto WLM may fit perfectly. 

## How to find you are using Auto WLM?

You can find this in 2 methods. By default auto WLM is enabled while creating the Parameter group.  You can find this out on your RedShift console.

![Auto%20WLM%2024b485ca3a694013972316f147e3992f/Untitled.png](Auto%20WLM%2024b485ca3a694013972316f147e3992f/Untitled.png)

The other way is from SQL:

If the result is greater than or equal to 1, then you are using the auto WLM.

```sql
select
	count(*)
FROM
	stv_wlm_service_class_config
WHERE
	service_class >= 100;
```

## Tips to tune Auto WLM:

You can dynamically change the queue priority without any downtime. Lets see this example.

- Queue 1 - ETL (1AM to 6AM)
- Queue 2 - Reports (6AM to 6PM)
- Queue 3 - Maintenance (6PM to 12AM)

Here we know when the ETL, Report and maintenance will happen. So we can use lambda to change the queue priority. 

[Untitled](https://www.notion.so/e8073b7bae9a44308d3e8a743dafc7e6)

 

**Concurrency scaling:** 

This is another great option, you can add concurrency scaling to handling your Report queries, they can benefit from this. 

## External Links:

1. [RedShift Auto WLM](https://www.intermix.io/blog/automatic-wlm/)
2. [RedShift Auto WLM with query priority](https://www.intermix.io/blog/redshift-automatic-wlm-with-query-priority/)