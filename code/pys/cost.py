import boto3
import json
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def lambda_handler(event, context):
    # AWS Cost Explorer client
    cost_explorer = boto3.client('ce', region_name='us-east-1')
    
    # Get the cost and usage data
    response = cost_explorer.get_cost_and_usage(
        TimePeriod={
            'Start': '2022-01-01',
            'End': '2022-01-31'
        },
        Granularity='MONTHLY',
        Metrics=[
            'BlendedCost',
        ],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'REGION'
            },
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    # Parse the response and format the cost data
    cost_data = {}
    for result_by_time in response['ResultsByTime']:
        for group in result_by_time['Groups']:
            region = group['Keys'][0]
            service = group['Keys'][1]
            cost = group['Metrics']['BlendedCost']['Amount']
            
            if region not in cost_data:
                cost_data[region] = {}
            
            cost_data[region][service] = cost
    
    # Convert the cost data to JSON
    cost_json = json.dumps(cost_data, indent=4)
    
    # Send the cost data via email
    send_email(cost_json)

def send_email(cost_data):
    # Email configuration
    sender_email = 'your_sender_email@example.com'
    receiver_email = 'your_receiver_email@example.com'
    smtp_server = 'smtp.example.com'
    smtp_port = 587
    smtp_username = 'your_smtp_username'
    smtp_password = 'your_smtp_password'
    
    # Create a multipart message
    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = receiver_email
    message['Subject'] = 'AWS Cost Report'
    
    # Attach the cost data as plain text
    message.attach(MIMEText(cost_data, 'plain'))
    
    # Send the email
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(smtp_username, smtp_password)
        server.send_message(message)
