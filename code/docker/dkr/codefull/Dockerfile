FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-add-repository --yes --update ppa:ansible/ansible && \
    apt-get install -y ansible && \
    apt-get install -y curl && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    apt-get install -y terraform && \
    apt-get install -y awscli && \
    apt-get install -y git && \
    apt-get install -y python3-pip && \
    pip3 install awscli --upgrade && \
    apt-get install -y ruby-full && \
    gem install aws-sdk-codedeploy aws-sdk-codepipeline aws-sdk-codebuild

CMD ["/bin/bash"]
