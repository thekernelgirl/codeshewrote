# Downwnload Ansible playbooks from S3 bucket
aws s3 sync s3://celerium-automation/playbooks/ /app/playbooks/

# Execute Ansible playbook
ansible-playbook /app/playbooks/<your-playbook>.yml
