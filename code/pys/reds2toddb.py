import redis
import boto3

# Connect to Redis cluster
redis_client = redis.Redis(host='your-redis-cluster-endpoint', port=6379)

# Retrieve data from Redis
data = redis_client.get('your-key')

# Connect to DynamoDB
dynamodb_client = boto3.client('dynamodb')

# Create table
table_name = 'your-table-name'
dynamodb_client.create_table(
    TableName=table_name,
    KeySchema=[
        {
            'AttributeName': 'id',
            'KeyType': 'HASH'
        }
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'id',
            'AttributeType': 'S'
        }
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    }
)

# Insert data into table
dynamodb_client.put_item(
    TableName=table_name,
    Item={
        'id': {'S': 'your-id'},
        'data': {'S': data}
    }
)
