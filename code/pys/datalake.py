import boto3

# Create a client for Athena
athena_client = boto3.client('athena')

# Define the SQL query to extract data from Redis cluster
query = "SELECT * FROM redis_cluster_table"

# Define the S3 bucket where the query results will be stored
output_location = 's3://your-bucket-name/athena-results/'

# Execute the query and store the results in S3
response = athena_client.start_query_execution(
    QueryString=query,
    ResultConfiguration={
        'OutputLocation': output_location,
    }
)

# Print the query execution ID
print('Query execution ID:', response['QueryExecutionId'])
