
## RStoolKit Result: WLM max connection hit

RedShift is an OLAP database system. It support upto 500 connections. But only 50 allowed to run concurrently. If you are hitting more connections means sometimes its fine but something you are accessing it as an Transactional database which is bad. Even if you hit more connections, but your WLM is well tunned then you don't need to worry about this.

## Find the Max connection hit hour:

You can use the [RedShift Admin script](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/wlm_apex_hourly.sql) to figure out what is your peak hour(when you are getting more number of connections). 

This is a CPU intensive query, single node cluster will consumpe full CPU. so please run this during non production hours, or closly monitor the cluster.

Run the `wlm_apex_hourly.sql` query.

![/src/img/highconnection.png](/src/img/highconnection.png)

From the above result, you can see my peak hour is 21 to 23. During this window Im getting more number of connections. 

## How to fix this problem:

Actually there is no fix for this. More connections are find. But remember 500 is the hard limit in RedShift. But you can optimize this to quickly run and exit from the cluster. 

- Tune the WLM (Auto or Manual)
- If possible use dynamic WLM to allocate more resource during this window.
    - [Dynamic WLM from RedShift utilities](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/WorkloadManagementScheduler)
    - [Dynamic WLM with simple lambda function](https://thedataguy.in/redshift-dynamic-wlm-lambda/)
- You are frequnetly encounter into this issue, then think about implementing a proxy on top of redshift.
    - [Heimdall proxy](https://aws.amazon.com/blogs/apn/improving-application-performance-with-no-code-changes-using-heimdalls-database-proxy-for-amazon-redshift/)
    - [pgpool with Amazon ElastiCache](https://aws.amazon.com/blogs/big-data/using-pgpool-and-amazon-elasticache-for-query-caching-with-amazon-redshift/)

## External Links:

1. [WLM - System tables and views](https://docs.aws.amazon.com/redshift/latest/dg/cm-c-wlm-system-tables-and-views.html)
2. [RedShift QMR rules](https://docs.aws.amazon.com/redshift/latest/dg/cm-c-wlm-queue-assignment-rules.html)
3. [Optimizing WLM](https://www.intermix.io/blog/4-simple-steps-to-set-up-your-wlm-in-amazon-redshift-the-right-way/)