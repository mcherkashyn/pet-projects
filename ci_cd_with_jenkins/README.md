![67667](https://user-images.githubusercontent.com/107031880/230799807-7622d5d7-3ece-490f-9290-fbb2a2c533ea.png)

In this project, I use Terraform to automate the deployment of a simple Docker web application, using Jenkins for CI/CD pipeline.

Project steps:

1. Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, EC2 instance for running Jenkins. Also, writing Jenkinsfile.

2. Deployment of all the resources to AWS and entering Jenkins for pipeline configuration.

3. Testing my deployment: once the CI/CD pipeline cycle ended, I can test my Docker web application, using EC2 instance Public IP to make sure that the application is working correctly.
