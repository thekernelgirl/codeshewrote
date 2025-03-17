import boto3
import csv

# Initialize the Boto3 client for EC2
ec2 = boto3.client('ec2')

# Get a list of all AMIs in your account
response = ec2.describe_images(Owners=['self'])

# Define the CSV file name
csv_file = 'ami_descriptions.csv'

# Open the CSV file for writing
with open(csv_file, 'w', newline='') as file:
    writer = csv.writer(file)

    # Write the header row
    writer.writerow(['Image ID', 'Name', 'Description'])

    # Iterate through the list of AMIs and write their information to the CSV
    for image in response['Images']:
        image_id = image['ImageId']
        name = image['Name'] if 'Name' in image else 'N/A'
        description = image['Description'] if 'Description' in image else 'N/A'
        writer.writerow([image_id, name, description])

print(f"AMIs and their descriptions have been saved to {csv_file}")

