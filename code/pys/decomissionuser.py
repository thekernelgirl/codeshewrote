import boto3

def lambda_handler(event, context):
    # Get the user's email from the event input
    email = event['email']
    
    # Decommission the user
    try:
        iam_client = boto3.client('iam')
        iam_client.delete_user(UserName=email)
        
        # Send success notification
        send_notification(email, 'User Decommissioned Successfully')
        
        return {
            'statusCode': 200,
            'body': 'User decommissioned successfully'
        }
    except Exception as e:
        # Send error notification
        send_notification(email, f'Failed to decommission user: {str(e)}')
        
        return {
            'statusCode': 500,
            'body': f'Failed to decommission user: {str(e)}'
        }

def send_notification(email, message):
    # Here, you can implement your own code to send notifications,
    # such as sending an email or using a messaging service
    pass

#Payload looks like this. 
#
#{
#    "email": "user@example.com"
#}
#
#
#
