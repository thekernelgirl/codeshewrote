In this Dockerfile, we start with the python:3.8-slim-buster image as the base. We then install the AWS CLI and copy our lambda function code into the container. Next, we set the environment variables for AWS access key, secret key, and default region. Finally, we set the entrypoint command to "aws" and the default command to invoke the lambda function.

Make sure to replace `<YOUR_AWS_ACCESS_KEY_ID>`, `<YOUR_AWS_SECRET_ACCESS_KEY>`, `<YOUR_AWS_REGION>`, and `<YOUR_LAMBDA_FUNCTION_NAME>` with your own values.

To build the Docker image, navigate to the directory containing the Dockerfile and run the following command:

```
docker build -t <YOUR_IMAGE_NAME> .
```

To run the Docker container and invoke the lambda function, use the following command:

```
docker run <YOUR_IMAGE_NAME>
```

Note that you may need to configure the AWS CLI in the container if you have not done so already. You can use the `aws configure` command inside the Dockerfile or manually configure it during runtime.
