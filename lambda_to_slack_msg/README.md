In this project I use Terraform to deploy the Lambda function to AWS. After triggering the function, the test message is sent to the Slack chat. The Slack token is encrypted with AWS KMS key.

Project steps:

1. Create a secret with a Slack bot token in the AWS Secrets Manager.

2. Apply the Terraform configuration.

3. Trigger the Lambda function.
