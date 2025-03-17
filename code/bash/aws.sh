#!/bin/bash

# Function to list and select AWS profiles
switch_aws_profile() {
    echo "Available AWS Profiles:"

    # Extract profile names from the credentials file
    local profiles=$(grep '\[' ~/.aws/credentials | sed 's/\[\(.*\)\]/\1/')
    local PS3="Please select an AWS profile: "

    select profile in $profiles; do
        if [ -n "$profile" ]; then
            export AWS_PROFILE=$profile
            echo "Switched to AWS profile: $AWS_PROFILE"
            break
        else
            echo "Invalid option. Please try again."
        fi
    done
}

# Call the function to start the profile switcher
switch_aws_profile

