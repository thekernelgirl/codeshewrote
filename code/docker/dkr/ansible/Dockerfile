# Base image with Ansible
FROM ansible/ansible:latest

# Install AWS CLI
RUN apt-get update && \
    apt-get -y install python3-pip && \
    pip3 install awscli

# Set working directory
WORKDIR /app

# Copy AWS credentials and config files
COPY .aws/ /root/.aws/

# Copy the shell script to download and execute Ansible playbook
COPY deploy.sh /app/

# Set execute permissions for the shell script
RUN chmod +x /app/deploy.sh

# Run the shell script to download and execute Ansible playbook
CMD ["/bin/sh", "/app/deploy.sh"]
