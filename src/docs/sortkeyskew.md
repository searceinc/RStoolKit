
## RStoolKit Result: Sort Key skew is greater then 4

Sort key in redshift is something equant to index in a relational database. The row inside the tables will be sorted bases on this sort key. Sort Key skew means ratio of the size of the largest non-sort key column to size of the sort key(or if you have multiple columns, then the first column will be considered).

**Example:**

If your sort key skew is 5, which means that you query can get the data on the sort key column in 1 block, but for other columns it may need to read 5 blocks which is bad for your cluster's performance. 

## Find the tables with high sort key skew:

```sql
select
	"schema",
	"table",
	skew_sortkey1
FROM
	svv_table_info
WHERE
	sortkey1 IS NOT NULL
	AND skew_sortkey1 >= 4
	AND "schema" not like 'pg_temp%'
order by
	skew_sortkey1 desc;
```

## How to fix this problem:

Generally if you have compression on the sort key column, then you may run into this issue. Sometimes, you can see the tables in this list even though if the sort key column is RAW or uncompressed. This is due to if you choose sort key and disk key as same and this table have skew. To solve this issue, you need to recreate this table without compression on the sort key column.

## External Links:

1. [Why you should not compress the sort key column](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/Investigations/EarlyMaterialization.md)
2. [What is sort key skew](https://stackoverflow.com/questions/35857481/what-does-the-column-skew-sorkey1-in-amazon-redshifts-svv-table-info-imply)
3. [How to choose the right sort key on existing table](https://thedataguy.in/rskit/sortkeys)
4. [Analyze the table design](https://docs.aws.amazon.com/redshift/latest/dg/c_analyzing-table-design.html)
5. [Table inspector from RedShift utilities](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/table_inspector.sql)