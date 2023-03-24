![diagram_3](https://user-images.githubusercontent.com/107031880/227433901-e41da33c-777f-4a40-863f-159cb8a242f5.png)

In this project, I use Terraform to automate the deployment of a simple web application, using GitHub actions for CI/CD pipeline.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, EC2 instance for running the web application. Also, I create an S3 bucket for Terraform state files.

2. Creation of a GitHub actions workflow configuration file and deployment of all the resources to AWS.

3. Testing my deployment: once the CI/CD pipeline cycle ended, I can test my web application, using EC2 instance Public IP to make sure that the application is working correctly.
