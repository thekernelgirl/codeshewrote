import requests
import json
from datetime import datetime

# Confluence API credentials
confluence_username = 'your_username'
confluence_password = 'your_password'
confluence_base_url = 'https://your-confluence-site.com'
page_id = '123456'  # Replace with the actual Confluence page ID

# Define the data for your table (date, time, and activities)
table_data = [
    {"date": "2023-10-20", "time": "10:00 AM", "activity": "Meeting"},
    {"date": "2023-10-21", "time": "2:30 PM", "activity": "Presentation"},
    {"date": "2023-10-22", "time": "11:15 AM", "activity": "Training"},
]

# Create a table in Confluence Markup Language (CML) format
table_cml = """
||Date||Time||Activity||
|%s|%s|%s|
""" % ("|".join([""] * 3), "|".join(["---"] * 3))

for data in table_data:
    table_cml += "|%s|%s|%s|\n" % (data["date"], data["time"], data["activity"])

# Define the Confluence page update payload
update_data = {
    "version": {
        "number": 1  # Increment the version number to update the page
    },
    "title": "Your Page Title",  # Replace with the page title
    "type": "page",
    "body": {
        "storage": {
            "value": table_cml,
            "representation": "wiki"
        }
    }
}

# URL for updating the Confluence page
update_url = f'{confluence_base_url}/wiki/rest/api/content/{page_id}'

# Send the update request
response = requests.put(
    update_url,
    auth=(confluence_username, confluence_password),
    headers={"Content-Type": "application/json"},
    data=json.dumps(update_data)
)

if response.status_code == 200:
    print(f"Confluence page updated successfully.")
else:
    print(f"Failed to update Confluence page. Status Code: {response.status_code}")

