In this project, I use Terraform to deploy the infrastructure to AWS, it includes such monitoring solution: EC2 master instance for running Prometheus for scraping metrics and Grafana, 
an auto-scaling group with slave instances, which send metrics to master instance with node_exporter.

Project steps:

Writing Terraform config for AWS infrastructure creating, it consists: creation of a network, master EC2 instance and auto-scaling group.

Testing my deployment: after infrastructure deployment, I can connect to Grafana with master EC2 instance public IP, create a data source and a dashboard to see the slave instances metrics.
