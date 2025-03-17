#!/bin/bash

aws cloudformation deploy \
    --template-file template.yaml \
    --stack-name my-stack \
    --parameter-overrides \
        ParameterKey=InstanceType,ParameterValue=t2.micro \
        ParameterKey=KeyName,ParameterValue=my-key-pair \
    --capabilities CAPABILITY_IAM
