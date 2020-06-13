
## RStoolKit Results: Non scanned Tables (based on STL Scan)

STL_SCAN is a system table that will capture all of your query execution details.  But generally these system tables are never persist the data. But based on the very recent queries we can find the tables that are never scanned.  

## Find the non scanned tables:

```sql
select
	"schema",
	"table",
	"size"
from
	pg_catalog.svv_table_info
where
	table_id not in (
	select
		DISTINCT(tbl)
	from
		stl_scan )
order by
	size desc;
```

## How to fix the problem:

Actually the reason for finding the non used tables to clean them all it is not required. But from the about query results, if you are sure that these XYZ tables are not needed then just clean them or take a final backup and delete them. But if you are not sure? 

- Start backup the [STL_SCAN](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_SCAN.html) table to S3 or somewhere on daily basis for a week or N days.
- Create a new table with that backup.
- Run the above query, now will get the non scanned tables. It'll help to make better decision.

## External Links:

1. [STL_SCAN - Documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_SCAN.html)
2. [Persist the system tables - Lambda](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/SystemTablePersistence)
3. [Export the system tables to s3 - Stored Procedure](https://thedataguy.in/export-redshift-system-tables-views-to-s3/)