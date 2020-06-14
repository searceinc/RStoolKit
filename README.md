# RStoolKit - RedShift Health Check
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/searceinc/RStoolKit/commits/master)
[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://github.com/searceinc/RStoolKit/blob/master/LICENSE)

If you are managing a single node RedShift cluster or a big giant multi node cluster, you are responsible for the its performance. RedShift performance optimization starts from the table designing. We have an amazing RedShift Utilities repo where we can get a bunch of SQL queries to check the cluster's status. But unfortunately many times we may end up with many queries but the results are positive, no need to optimize anything. 

The goal of this project is concentrate only on where is the bottleneck in your RedShift cluster and a complete health check recipe in one place. Once it identified the issues in the cluster, you don't need to run somewhere to find the solutions for them. This utility will take you to the documentation page where you'll find the cause for this issue and how to solve them. Also these doc pages contains External links section where you can find scripts from other trusted repositions like AWS RedShift Utilities, AWS Blogs and some documentation to learn and fix the issue.

## What we are checking in your cluster?

1. **Design** - Find the wrong distribution and sort keys, compression issues and etc. 
2. **Table** - Table related issues like without sort key, unused tables and etc.
3. **WLM** - Find the max connection hit, check the concurrency is good or not, number of queues.
4. **Vacuum** - Tables never performed vacuum, ghost rows, tombstone blocks and etc. 
5. **Performance** - Disk based queries, High CPU queries and etc. 

### List of checks and their priority:

|Category   |Check ID|Findings                                                |Threshold-Red      |Threshold-Yellow      |Threshold-Green|
|-----------|--------|--------------------------------------------------------|-------------------|----------------------|---------------|
|Design     |1       |Tables without sort keys                                |Greater than 10    |Between 1 to 10       |0              |
|Design     |2       |Sort key column compressed                              |Greater than 10    |Between 1 to 10       |0              |
|Design     |3       |Sort key skew Greater than  4                           |Greater than 10    |Between 1 to 10       |0              |
|Design     |4       |Tables with high Skew                                   |Greater than 10    |Between 1 to 10       |0              |
|Design     |5       |Tables without compression                              |Greater than 10    |Between 1 to 10       |0              |
|WLM        |6       |WLM queue wait time Greater than  1min                  |Greater than 900   |Between 180 to 900    |Less than  180 |
|WLM        |7       |WLM max connection hit                                  |Greater than 400   |Between 100 to 400    |Less than 100  |
|WLM        |8       |Number of WLM queue                                     |1                  |Between 2 and 3       |Greater than 3 |
|WLM        |9       |Auto WLM enabled                                        |-                  |0                     |Greater than 1 |
|WLM        |10      |Max concurrency for a slot                              |Greater than 20    |Between 15 and 20     |Less than 16   |
|WLM        |11      |WLM commit queue wait                                   |Greater than 120   |Between 60 to 120     |Less than 60   |
|Vacuum     |12      |Ghost rows                                              |Greater than 100000|Between 1000 to 100000|Less than 1000 |
|Vacuum     |13      |Tables never performed vacuum (based on STL_Vacuum)     |Greater than 5     |Between 1 and 5       |0              |
|Vacuum     |14      |Table vacuum older than 5 days                          |Greater than 10    |Between 5 and 10      |Less than 5    |
|Vacuum     |15      |Tables with tombstone blocks                            |Greater than 5     |Between 1 and 5       |0              |
|Vacuum     |16      |Tables with missing stats                               |Greater than 5     |Between 1 and 5       |0              |
|Vacuum     |17      |Tables with stale stats (Greater than  5 percent)       |Greater than 5     |Between 1 and 5       |0              |
|Table      |18      |Top size tables                                         |Greater than 2     |Between 1 and 2       |0              |
|Table      |19      |Table with high number of alerts (Greater than 3 alerts)|Greater than 5     |Between 1 and 5       |0              |
|Table      |20      |Non scaned Tables (based on STL Scan)                   |Greater than 5     |Between 1 and 5       |0              |
|Table      |21      |Tables without backup                                   |Greater than 0     |No                    |0              |
|Table      |22      |Tables with fragmentation                               |Greater than 5     |Between 1 and 5       |0              |
|Performance|23      |Disk based queries                                      |Greater than 500   |Between 300 and 500   |Less than 300  |
|Performance|24      |COPY not optimized                                      |Greater than 5     |Between 1 and 5       |0              |
|Performance|25      |High CPU queries (Greater than 80 Percent)              |Greater than 10    |Between 5 and 10      |Less than 5    |
|Performance|26      |Most frequent Alert (Greater than  500 times)           |Greater than 10    |Between 5 and 10      |Less than 5    |
|Performance|27      |Long running queries (Greater than  30mins)             |Greater than 300   |Between 100 and 300   |Less than 100  |
|Performance|28      |Max temp space used by queries                          |Greater than 10    |Between 5 and 10      |Less than 5    |


## Before running the script:

We optimized this query as much as possible. 

- We recommend to run this on your non peak hours.
- If you have a single node cluster, then keep an eye on CPU (but it'll not go more than 50% or 60%).
- If your cluster is launched within 3 days(new cluster or if you did elastic resize), then the system tables may not have enough data to find out the bottleneck. So at least 3 days data is recommend on STL, SVV tables to run this script.

## Run the Health Check:

### SQL script:

- You can just download the **[health-check.sql](https://raw.githubusercontent.com/searceinc/RStoolKit/master/health-check.sql)** script from this repo and run this on your favourite UI tool like pgAdmin, DBeaver or Aginity workbench.
- If you are using command line tool `psql client` then you can import this via command line.

```bash
wget https://raw.githubusercontent.com/searceinc/RStoolKit/master/health-check.sql
psql -h redshift-endpoint -U user -p 5439 -d db_name < health-check.sql
```

### Sample Report:

![/src/img/sql-result.jpg](/src/img/sql-result.jpg)

## Scheduled Report via Lambda:

If you want run this health check on every week or some particular frequency, you can use AWS Lambda to run this health check and send the report over the email with SES. We have created a **CloudFormation** template to create this lambda function. RedShift and SES details can be passed through the Lambda environment variables. Please follow the below instructions to deploy this.

### Changes in RedShift:

No changes on the cluster level, but lambda needs to access the RedShift cluster. So the subnets that you are going to use for Lambda those IP ranges needs to be whitelisted on RedShift's security group.

### Changes in the VPC:

- We strongly recommend that to use SES with VPC endpoints for security reasons.
- Create a VPC Endpoint on SES supported Regions and attach to your RedShift VPC.
- While creating this Endpoint it will you to pick subnets where SES endpoints are available(Still many AZs is not supporting this).
- Create a Security Group for AWS Lambda and allow the 25, 465, 587, 2465, or 2587 port to the  subnets IP Range that you in your previous step.
- More detailed information from the AWS Doc: [https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-set-up-vpc-endpoints.html](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-set-up-vpc-endpoints.html)
- Create an AWS IAM user for SES to send emails. Follow this [link](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html) for more information.

### Resources will be created by the Cloud Formation:

- IAM role for Lambda.
- Custom policy for lambda [[AWSLambdaVPCAccessExecutionRole](https://console.aws.amazon.com/iam/home?region=us-east-1#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2Fservice-role%2FAWSLambdaVPCAccessExecutionRole) and [AWSLambdaBasicExecutionRole](https://console.aws.amazon.com/iam/home?region=us-east-1#/policies/arn%3Aaws%3Aiam%3A%3Aaws%3Apolicy%2Fservice-role%2FAWSLambdaBasicExecutionRole)]
- Lambda function with Python 3.7

### Things you need to take care:

Its an addition step for security. The function will work without this change, but recommend to enable the KMS encryption to this.

- This cloud formation stack will use the RedShift credentials and SES credentials as an Environment variables.
- Its all in plain text. To ensure the security you can encrypt them using KMS. For more information please follow this [link](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html).

### Cloud Formation Parameters:

|Parameter name     |Purpose                       |
|-------------------|------------------------------|
|REDSHIFTendpoint   |RedShift cluster endpoint     |
|REDSHIFTdatabase   |RedShift Database name        |
|REDSHIFTuser       |User Name for RedShift Cluster|
|REDSHIFTpasswd     |Password for RedShift Cluster |
|REDSHIFTport       |RedShift port                 |
|SESregion          |SES region                    |
|SESendpoint        |SES SMTP endpoint             |
|SESusername        |SES Access Key                |
|SESpassword        |SES Secret Key                |
|SESsendermail      |SES verified sender email     |
|SESrecipient       |Email recipients              |
|S3codebucket       |Lambda code bucket            |
|S3codekey          |lamda zip file location       |
|lambdaSecurityGroup|Security group for lambda     |
|lambdaSubnetIds    |Subnets for the Lambda        |


### Deploy this Stack (Regions where SES is supported):
|Region  | URL (Click the Launch stack icon)|
|-------------------------------|----------------------------------------------------------------------------------------------------------------------|
|US East (N. Virginia)          |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|US West (Oregon)               |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Asia Pacific (Mumbai)          |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-south-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Asia Pacific (Sydney)          |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Canada (Central)               |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=ca-central-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Europe (Frankfurt)             |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Europe (Ireland)               |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|Europe (London)                |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=eu-west-2#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|
|South America (São Paulo)      |[![](/src/img/cloudformation-launch-stack.png)](https://console.aws.amazon.com/cloudformation/home?region=sa-east-1#/stacks/new?stackName=myteststack&templateURL=https://searce-opensource.s3.amazonaws.com/rstoolkit-cf-template/rstoolkit-cloudformation-template.yaml/?target=_blank)|

### Manual Deployment (If your region is not listed on the above list)

The above list is prepared if SES is offically supported. If you want to use this lambda function, still you can deploy it on the other regions, but you need to take care of the Email part from the lambda code. (Still we didn't test this option)

* Or use SES in another region.
	* Create a SES user on any supported region, and verify an email address.
	* Create NAT gateway and attach it to a new route table.
	* Create or choose any exsiting subnets to use this NAT gateway.
	* While launching the CF template select the subnet that has NAT gate way.
* [Download](https://github.com/searceinc/RStoolKit/blob/master/rstoolkit-lambda-function.zip) the Lambda code
* [Download](https://github.com/searceinc/RStoolKit/blob/master/rstoolkit-cloudformation-template.yaml/?target=_blank) CloudFormation template

### Sample Report:

![/src/img/lambda-result.jpg](/src/img/lambda-result.jpg)

## License & Contributing:

- **`RStooKit`** is free and open sourced under the [MIT license](https://github.com/searceinc/RStoolKit/blob/master/LICENSE).
- We appreciate and happy to accept the pull requests from anyone. Read the [contributing guide](https://github.com/searceinc/RStoolKit/blob/master/CONTRIBUTING.md) before submit your pull request.







