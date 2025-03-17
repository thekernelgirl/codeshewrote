import boto3

def lambda_handler(event, context):
    # Specify the region and table name
    region = 'us-west-2'
    table_name = 'your-dynamodb-table-name'

    # Create a DynamoDB client
    dynamodb = boto3.client('dynamodb', region_name=region)

    # Get the current time
    current_hour = int(event['time'].split(':')[0])

    # Scale read and write capacity based on the time
    if current_hour >= 6 and current_hour < 12:
        # Morning time, scale up the capacity
        dynamodb.update_table(
            TableName=table_name,
            ProvisionedThroughput={
                'ReadCapacityUnits': 100,  # Set the desired read capacity units
                'WriteCapacityUnits': 100  # Set the desired write capacity units
            }
        )
    elif current_hour >= 18 or current_hour < 6:
        # Night time, scale down the capacity
        dynamodb.update_table(
            TableName=table_name,
            ProvisionedThroughput={
                'ReadCapacityUnits': 10,  # Set the desired read capacity units
                'WriteCapacityUnits': 10  # Set the desired write capacity units
            }
        )
