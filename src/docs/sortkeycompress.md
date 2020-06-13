
## RStoolKit Result: Sort key column compressed

Generally its best practice to compress all the columns in RedShift to get the better performance. But you should not compress the sort key columns. If you have multiple column in your sort key then don't compress the first column of the sort key.

RedShift using both early materialization and late materialization. In early materialization the data will be filtered at the first step before a join or a filter. But in late materialization, the row numbers will be filtered instead of the data. For late materialization its ok to compress the sort key column, but RedShift will not use Late materialization for all the queries. 

> **Pro Tip:** A [detail blog post](https://thedataguy.in/redshift-do-not-compress-sort-key-column/) with visual example of how sort key compression is affecting the performance.

## Find tables with Sort key column compressed:

```sql
select
	"schema",
	"table"
FROM
	pg_catalog.svv_table_info
WHERE
	sortkey1 IS NOT NULL
	AND sortkey1_enc <> 'none'
	AND "schema" not like 'pg_temp%';
```

## How to fix this problem?

We cannot change/disable/enable the compression on the existing columns in redshift. So create a new table and copy the data from the existing table. 

## External Links:

1. [RedShift table design playbook](https://aws.amazon.com/blogs/big-data/amazon-redshift-engineerings-advanced-table-design-playbook-distribution-styles-and-distribution-keys/)
2. [Why you shouldn't compress the sortykey column from SO?](https://stackoverflow.com/questions/61546930/redshift-why-you-shouldnt-compress-the-sortykey-column)
3. [Another real world example of how compressed sort key is affecting performance by an AWS engineer](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/Investigations/EarlyMaterialization.md)
4. How to choose the right sort key on existing table - [Link 1](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/predicate_columns.sql), [Link 2](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/filter_used.sql)
5. [Analyze the table design](https://docs.aws.amazon.com/redshift/latest/dg/c_analyzing-table-design.html)
6. [Table inspector from RedShift utilities](https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminScripts/table_inspector.sql)