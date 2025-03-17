FROM amazon/aws-cli:2.2.44

# Install CodeDeploy agent
RUN apt-get update && \
    apt-get install -y ruby && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -s https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install -o /tmp/aws-codedeploy-install && \
    chmod +x /tmp/aws-codedeploy-install && \
    /tmp/aws-codedeploy-install auto && \
    rm /tmp/aws-codedeploy-install

# Install CodePipeline CLI
RUN curl -sL https://github.com/aws/aws-cli/archive/2.2.44.tar.gz | tar xz && \
    cd aws-cli-2.2.44 && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir --upgrade awscli && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /aws-cli-2.2.44

# Copy CloudFormation template and scripts
COPY cloudformation-template.yml /
COPY deploy.sh /

# Set environment variables
ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=<your_access_key_id>
ENV AWS_SECRET_ACCESS_KEY=<your_secret_access_key>

# Run deployment script
