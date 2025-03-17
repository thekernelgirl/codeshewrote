import subprocess
import boto3
import os

# AWS and Redshift configuration
aws_access_key_id = 'AKIAV2OCMPWBYZ3M3ZGU'
aws_secret_access_key = 'gajm185IZHqQk6MXg6gsTL7xnUCIYkBcKY6PKLI0'
s3_bucket = 'cel-p1-event-400376495491-001'
s3_prefix = 'data/1030/'  # Path to your S3 prefix
redshift_host = 'cel-p1-event-400376495491-000.cg5uo8k6i0dw.us-east-2.redshift.amazonaws.com'
redshift_port = '5439'
redshift_database = 'celp1event400376495491000/1030'
redshift_user = 'celuser'
redshift_password = 'JXjRnTY20Bqbwmzed+qHhZANaYo='
redshift_table = '1030events'

# Initialize AWS S3 client
s3 = boto3.client('s3',
                  aws_access_key_id=aws_access_key_id,
                  aws_secret_access_key=aws_secret_access_key)

# List objects in the S3 prefix
objects = s3.list_objects_v2(Bucket=s3_bucket, Prefix=s3_prefix)

# Process and load gzipped JSON files into Redshift
for s3_object in objects.get('Contents', []):
    s3_key = s3_object['Key']
    if s3_key.endswith('.json.gz'):
        # Execute the COPY command to load data from the JSON file in S3 into Redshift
        copy_command = f"""COPY {redshift_table}
        FROM 's3://{s3_bucket}/{s3_key}'
        CREDENTIALS 'aws_access_key_id={aws_access_key_id};aws_secret_access_key={aws_secret_access_key}'
        GZIP
        MANIFEST
        JSON 'auto'
        """

        # Run the COPY command using the psql command-line utility
        psql_command = f"""psql -h {redshift_host} -p {redshift_port} -d {redshift_database} -U {redshift_user} -w -c "{copy_command}" -W {redshift_password}"""
        subprocess.call(psql_command, shell=True)

