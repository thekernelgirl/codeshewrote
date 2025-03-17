# Use an official lightweight Python image.
# Python is used here for demonstration purposes to potentially generate or modify the YAML file.
FROM python:3.8-slim

# Install kubectl
RUN apt-get update && \
    apt-get install -y curl && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Copy the deployment YAML file into the image
COPY deployment.yaml /deployment.yaml

# Assuming the container runs in an environment where it has access to a Kubernetes cluster,
# you might want to use a script to apply the YAML.
# This could be a Python script, a Bash script, or simply the kubectl command itself.
# For example, a simple script to apply the YAML file might look like this:
# echo "Applying deployment.yaml to the Kubernetes cluster..."
# kubectl apply -f /deployment.yaml

# For demonstration purposes, let's assume we're using a bash script.
COPY deploy.sh /deploy.sh
RUN chmod +x /deploy.sh

# The entrypoint can be your script or any other command that applies the YAML file.
ENTRYPOINT ["/deploy.sh"]

