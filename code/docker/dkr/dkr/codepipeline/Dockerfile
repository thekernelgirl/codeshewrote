FROM amazonlinux:2

# Install necessary packages
RUN yum update -y && \
    yum install -y aws-cli && \
    yum install -y python3 && \
    yum install -y zip && \
    yum install -y git && \
    yum install -y curl && \
    yum install -y wget && \
    yum install -y unzip && \
    yum install -y jq && \
    yum install -y tar && \
    yum install -y gzip && \
    yum install -y openssl && \
    yum install -y openssh-client && \
    yum install -y gettext && \
    yum clean all

# Install AWS CodeDeploy agent
RUN wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install && \
    chmod +x ./install && \
    ./install auto && \
    rm ./install

# Set up AWS CLI configuration
RUN aws configure set region <your-region> && \
    aws configure set aws_access_key_id <your-access-key> && \
    aws configure set aws_secret_access_key <your-secret-key>

# Set up CodeDeploy deployment group
RUN aws deploy create-deployment-group --application-name <your-application-name> --deployment-group-name <your-deployment-group-name> --service-role-arn <your-service-role-arn>

# Set up CodePipeline pipeline
RUN aws codepipeline create-pipeline --cli-input-json file://pipeline.json

# Copy your application code into the container
COPY . /app

# Set the working directory
WORKDIR /app

# Run your application
CMD ["python3", "app.py"]
