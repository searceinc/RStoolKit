
## RStoolKit Result: Tables without sort key

RedShift store everything inside the 1MB data blocks. Also its using zone map concept to keep track of the minimum and the maximum number of value inside the blocks. Data inside the blocks will be stored in an order based on the sort key column.

Lets say you are going to store an integer data type column in RedShift. If you mention the sort key, then the data will be stored like below. You can that its properly organized. When the client wants to get the data from this tables with some where clause on this column, then RedShift will look into the zone map to find the matching blocks and read the data from those blocks.

**Example:**

```sql
select * from table where id between 32 and 35;
```

For this query, if your table has sort on the ID column, then it'll hit the block number 3 and retrieve the data. See the below image.

![Tables without sort key](/src/img/Tables-without-sort-key.png)

See the below image is an illustration of the same table without sort key. Now, if you run the same query it has to scan block 3,6 and 9 to retrieve the data. 

![Tables without sort key](/src/img/Tables-without-sort-key.png)

## Find the tables names without sort key

```sql
select
	"Schema",
	"table"
FROM
	pg_catalog.svv_table_info
WHERE
	sortkey1 IS NULL
	AND "schema" not like 'pg_temp%';
```

## How to fix the problem

If you are going to create a fresh table then you need to select the Sort key column which massively used in your where condition. Or if you want to create the sort keys on existing tables, then we can take a look at all the queries that you ran on this tables, and find right candidate for this sort key.

- Run the [predicate column query](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/predicate_columns.sql) from the RedShift admin script to analyse all the columns in a table and find the use on the where clause.
- Run the [filter used query](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/filter_used.sql) from the RedShift admin script to see the list of column used in the where condition.

## External Links:

1. [RedShift Admin Script - Predicate columns](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/predicate_columns.sql)
2. [RedShift Admin Script - Filter used](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/filter_used.sql)