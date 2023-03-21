In this project, I use Terraform to automate the deployment of a simple web application, using Jenkins for CI/CD pipeline.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, ec2 instance for running Jenkins.

2. Deployment of all the resources to AWS, writing Jenkinsfile and entering Jenkins for pipeline configuration.

3. Testing my deployment: once the CI/CD pipeline cycle ended, I can test my dockerized web application, using ec2 instance Public IP to make sure that the application is working correctly.

