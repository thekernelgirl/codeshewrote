import boto3
import redis

# Connect to Redis
redis_client = redis.Redis(host='localhost', port=6379, db=0)

# Connect to DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
table = dynamodb.Table('my-dynamodb-table')

# Scan Redis table and send data to DynamoDB
for key in redis_client.scan_iter():
    item = redis_client.hgetall(key)
    table.put_item(Item=item)
