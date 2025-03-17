# Use a minimal base image
FROM python:3.8-slim-buster

# Set working directory
WORKDIR /app

# Install AWS CLI
RUN apt-get update && \
    apt-get -y install curl unzip && \
    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Copy lambda function code to the container
COPY lambda_function.py /app

# Set environment variable for AWS access key and secret key
ENV AWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID>
ENV AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY>
ENV AWS_DEFAULT_REGION=<YOUR_AWS_REGION>

# Set entrypoint command for running AWS CLI commands
ENTRYPOINT ["aws"]

# Set default command for the container
CMD ["lambda", "invoke", "--function-name", "<YOUR_LAMBDA_FUNCTION_NAME>", "--payload", "{}"]
