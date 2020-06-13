
## RStoolKit Result: Tables without compression

Many of us already know the importance of the compression in RedShift. We need to reduce the size of the table and improve the query performance. But make sure you should not compress the sort key column or the first column of the sort key.

## Find the tables without compression:

```sql
select
	"schema",
	"table"
FROM
	pg_catalog.svv_table_info
WHERE
	encoded <> 'Y'
	AND "schema" not like 'pg_temp%'
```

## How to fix the problem:

We can compress the exisiting columns or change the compression type in RedShift. You have to recreate the table with compression. By default if you didn't mention anything during the table creation then RedShift will automatically pick the right compression algorithm. 

- For exsiting tables, run the **[Amazon Redshift Column Encoding Utility](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/ColumnEncodingUtility)** to choose the right compression algorithm.
- For new tables, pick the right compression or let RedShift choose best compression.

## External Link:

1. [RedShift Create table - Documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html)
2. [RedShift column encoding](https://docs.aws.amazon.com/redshift/latest/dg/c_Compression_encodings.html)
3. [Choosing a column compression type](https://docs.aws.amazon.com/redshift/latest/dg/t_Compressing_data_on_disk.html)
4. [Redshift column encoding utility](https://github.com/awslabs/amazon-redshift-utils/tree/master/src/ColumnEncodingUtility)