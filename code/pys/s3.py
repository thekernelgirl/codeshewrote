import os
import boto3
import json
import subprocess

# AWS and Redshift configuration
aws_access_key_id = 'AKIAV2OCMPWBYZ3M3ZGU'
aws_secret_access_key = 'gajm185IZHqQk6MXg6gsTL7xnUCIYkBcKY6PKLI0'
s3_bucket = 'cel-p1-event-400376495491-001'
s3_manifest_key = 'manifest_file.json'  # Path to your S3 prefix
redshift_host = 'cel-p1-event-400376495491-000.cg5uo8k6i0dw.us-east-2.redshift.amazonaws.com'
redshift_port = '5439'
redshift_database = 'celp1event400376495491000/1030'
redshift_user = 'celuser'
iamrole = 'arn:aws:iam::400376495491:role/service-role/AmazonRedshift-CommandsAccessRole-20231101T152019'
redshift_password = 'JXjRnTY20Bqbwmzed+qHhZANaYo='
redshift_table = '1030events'
table_name = 'event'


def lambda_handler(event, context):
    # Initialize AWS S3 client
    s3 = boto3.client('s3')

    # Download the manifest file from S3
    local_manifest_path = '/tmp/manifest_file.manifest'
    s3.download_file(s3_bucket, s3_manifest_key, local_manifest_path)

    # Execute the COPY command to load data using the manifest file into Redshift
    copy_command = f"""COPY {table_name}
    FROM 's3://{s3_bucket}/{s3_manifest_key}'
    --CREDENTIALS 'aws_access_key_id={aws_access_key_id};aws_secret_access_key={aws_secret_access_key}'
    IAM_ROLE '{iamrole}'
    timeformat 'YYYY-MM-DDTHH:MI:SS'
    MANIFEST
    GZIP
    JSON 'auto';
    """

    # Run the COPY command using the psql command-line utility
    psql_command = f"""psql -h {redshift_host} -p {redshift_port} -d {redshift_database} -U {redshift_user} -w -c "{copy_command}" -W {redshift_password}"""
    subprocess.call(psql_command, shell=True)

    return {
        'statusCode': 200,
        'body': json.dumps('Data import completed successfully!')
    }

