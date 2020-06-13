
## RStoolKit Results: COPY not optimized

RedShift internally splits its resources into multiple slices. Whenever we are going perform the COPY operation, then it'll parallelize the import bases on number of slices. Lets say if your cluster has 8 slices then 8 files can be imported parallelly.  So you need to have the number of files should be a multiple of the number of slices in your cluster.

## Find the COPY process that are not optimized:

```sql
WITH cte 
     AS (SELECT query, 
                Count(*) AS n_files 
         FROM   stl_s3client 
         WHERE  http_method = 'GET' 
                AND query > 0 
                AND transfer_time > 0 
         GROUP  BY query) 
SELECT a.query, 
       a.n_files AS number_of_files, 
       b.querytxt 
FROM   cte a 
       join stl_query b 
         ON a.query = b.query 
WHERE  n_files % (SELECT Count(slice) 
                  FROM   stv_slices) != 0 
ORDER  BY number_of_files DESC;
```

## Find the COPY process with optimized files:

```sql
WITH cte 
     AS (SELECT query, 
                Count(*) AS n_files 
         FROM   stl_s3client 
         WHERE  http_method = 'GET' 
                AND query > 0 
                AND transfer_time > 0 
         GROUP  BY query) 
SELECT a.query, 
       a.n_files AS number_of_files, 
       b.querytxt 
FROM   cte a 
       join stl_query b 
         ON a.query = b.query 
WHERE  n_files % (SELECT Count(slice) 
                  FROM   stv_slices) = 0 
ORDER  BY number_of_files DESC;
```

## How to fix this problem:

To perform an optimized COPY process please follow the below recommendations from AWS

1. The number of files should be a multiple of the number of slices in your cluster.
2. Split your load data files so that the files are about equal size, between 1 MB and 1 GB after compression
3. For optimum parallelism, the ideal size is between 1 MB and 125 MB after compression.

## External Links:

1. [RedShift COPY documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html)
2. [RedShift COPY - Best practice](https://docs.aws.amazon.com/redshift/latest/dg/c_loading-data-best-practices.html)
3. [STL_S3CLIENT - Documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_STL_S3CLIENT.html)