
## RStoolKit Results: Top size tables

You may or may not be monitoring your table's growth in terms of size. Sometimes this table growth will consume almost all the available disk space. But you can add few more nodes to solve this issue, but pricing is the concern here. 

**Tip**: Sometimes [disk based queries](https://thedataguy.in/disk-based-query-in-redshift/) also will consume more space, but when the query executed it'll be reclaimed. 

## Find the top sized tables

```sql
-- Find the tables where size is 40% of your total storage
select
	"schema",
	"table",
	size
FROM
	pg_catalog.svv_table_info
WHERE
	pct_used >= 40
```

## How to fix this problem:

This may not be the solution for everyone. Just adding an additional node will solve this. But if you are thinking about cost then you consider the below action items.

> **These tables are eligible for RedShift Spectrum**

- If the old data is not at all require then UNLOAD them into S3, then delete the data in RedShift.
- If the older data is needed but not frequently accessed, the spectrum is the right choice. Unload the tables to S3 or create external table. Then delete the old data on RedShift.
- If the data is not at all required and you find it is useless the directly delete the old data.
- And finally make sure any Bulk deletes will not reclaim the space, so don't forgot to run the vacuum.

## External Links:

1. [RedShift unload](https://docs.aws.amazon.com/redshift/latest/dg/r_UNLOAD.html) 
2. [Getting started with spectrum](https://docs.aws.amazon.com/redshift/latest/dg/c-getting-started-using-spectrum.html)
3. [External tables - Simplifying Spectrum](https://docs.aws.amazon.com/redshift/latest/dg/c-spectrum-external-tables.html) 
4. [Vacuum and Analyze utility - Shell](https://thedataguy.in/automate-redshift-vacuum-analyze-using-shell-script-utility/)
5. [Vacuum and Analyze utility - Python](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/AnalyzeVacuumUtility)