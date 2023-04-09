In this project, I use Terraform to automate the deployment of a simple Dockerized web application with CloudWatch logging, connected to an AWS RDS database.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, EC2 instance for running the web application, and RDS PostgreSQL database instance.

2. Deployment of the infrastructure using Terraform CLI to the cloud platform.

3. Testing my deployment: once the infrastructure is up and running, I can test my web application, using EC2 instance Public IP to make sure that the application is working correctly, connected to RDS database.
