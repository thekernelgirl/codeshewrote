import os
import subprocess
import boto3

# Load Redis Cluster Backup configuration
config_file = 'redis-cluster-backup.conf'
if not os.path.isfile(config_file):
    raise Exception(f'Configuration file {config_file} not found')
subprocess.run(['redis-cluster-backup', '-c', config_file])

# Upload backup files to S3
s3 = boto3.client('s3')
backup_path = '<local-backup-path>'
s3_bucket = '<s3-bucket-name>'
s3_prefix = '<s3-prefix>'
for root, dirs, files in os.walk(backup_path):
    for file in files:
        local_path = os.path.join(root, file)
        s3_key = os.path.join(s3_prefix, os.path.relpath(local_path, backup_path))
        s3.upload_file(local_path, s3_bucket, s3_key)
