import boto3
import pymysql

# Connect to RDS database
rds_host = "your-rds-hostname"
name = "your-db-username"
password = "your-db-password"
db_name = "your-db-name"
conn = pymysql.connect(rds_host, user=name, passwd=password, db=db_name, connect_timeout=5)

# Connect to DynamoDB table
dynamodb = boto3.resource('dynamodb', region_name='your-region-name')
table = dynamodb.Table('your-dynamodb-table-name')

# Retrieve data from RDS table
with conn.cursor() as cur:
    cur.execute("SELECT * FROM your-rds-table-name")
    rows = cur.fetchall()

# Insert data into DynamoDB table
with table.batch_writer() as batch:
    for row in rows:
        item = {
            'id': row[0],
            'name': row[1],
            'age': row[2]
        }
        batch.put_item(Item=item)

# Close RDS connection
conn.close()
