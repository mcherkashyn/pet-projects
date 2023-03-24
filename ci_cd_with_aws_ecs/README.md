In this project, I use Terraform to deploy the infrastructure to AWS, including AWS ECS for my simple Docker web application with CloudWatch logging feature. As CI/CD pipeline, I use GitHub actions.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, Elastic Load Balancer, CloudWatch logging, ECR repository and ECS for running the web application.

2. Creation of a GitHub actions workflow configuration file and deployment of all the resources to AWS (.github/workflows/deploy_to_aws_ecs.yml).

3. Testing my deployment: once the CI/CD pipeline cycle ended, I can test my web application, using ELB DNS name to make sure that the application is working correctly.
