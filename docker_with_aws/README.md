In this project, I use Terraform to automate the deployment of a simple Docker web application with CloudWatch logging feature.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, EC2 instance for running the web application, CloudWatch configuration and bash script for EC2 instance user data.

2. Deployment of the infrastructure using Terraform CLI to the cloud platform.

3. Testing my deployment: once the infrastructure is up and running, I can test my Docker web application, using EC2 instance Public IP and CloudWatch logging.
