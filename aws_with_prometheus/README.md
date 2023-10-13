![dffgfdgvdv](https://github.com/mcherkashyn/pet-projects/assets/107031880/72ad3067-e3ae-40c5-8afb-f1503861b041)

In this project I use Terraform to deploy the infrastructure to AWS, it includes such monitoring solution: EC2 master instance for running Prometheus and Grafana, 
an auto-scaling group with slave instances, which run node_exporter.

Project steps:

1. Apply the Terraform configuration.

2. Access Prometheus via IP address, go to the targets tab and check that the connection between the slave instances is successfully established. 

3. Access Grafana via IP address and configure a new data source to see metrics from the slave instances.
