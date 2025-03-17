import boto3
import smtplib
from email.mime.text import MIMEText

def lambda_handler(event, context):
    # Configure AWS credentials and region
    aws_access_key_id = 'YOUR_AWS_ACCESS_KEY_ID'
    aws_secret_access_key = 'YOUR_AWS_SECRET_ACCESS_KEY'
    aws_region = 'us-west-2'  # Replace with your desired AWS region
    
    # Configure Athena query parameters
    database = 'your_database_name'
    query = 'SELECT * FROM your_table_name LIMIT 10'  # Replace with your Athena query
    
    # Create Athena client
    athena_client = boto3.client('athena',
                                 aws_access_key_id=aws_access_key_id,
                                 aws_secret_access_key=aws_secret_access_key,
                                 region_name=aws_region)
    
    # Execute Athena query
    response = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={
            'Database': database
        },
        ResultConfiguration={
            'OutputLocation': 's3://your-bucket-name/athena-results/'
        }
    )
    
    # Get query execution ID
    query_execution_id = response['QueryExecutionId']
    
    # Wait for query execution to complete
    waiter = athena_client.get_waiter('query_execution_completed')
    waiter.wait(QueryExecutionId=query_execution_id)
    
    # Get query results
    results = athena_client.get_query_results(QueryExecutionId=query_execution_id)
    
    # Format query results as plain text
    result_text = ''
    for row in results['ResultSet']['Rows']:
        result_text += '\t'.join([field['VarCharValue'] for field in row['Data']]) + '\n'
    
    # Configure email parameters
    sender_email = 'your_sender_email@example.com'
    receiver_email = 'your_receiver_email@example.com'
    smtp_server = 'smtp.example.com'
    smtp_port = 587
    smtp_username = 'your_smtp_username'
    smtp_password = 'your_smtp_password'
    
    # Create email message
    message = MIMEText(result_text)
    message['Subject'] = 'Athena Query Result'
    message['From'] = sender_email
    message['To'] = receiver_email
    
    # Send email
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.sendmail(sender_email, receiver_email, message.as_string())
    
    return {
        'statusCode': 200,
        'body': 'Email sent successfully'
    }
