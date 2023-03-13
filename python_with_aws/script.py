import logging
import inspect
from marshmallow import Schema, fields, RAISE
from pprint import pprint
import json
import boto3, socket
from botocore.exceptions import ClientError



#ligging_config
logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)



#recieve_data_from_json_file
with open('variables.json') as f:
    variables = json.load(f)



#resources
#client = boto3.client('autoscaling')
client = boto3.client('ec2', 'us-east-1')
ec2 = boto3.resource('ec2', 'us-east-1')



class Create_resources():

    #create_vpc
    def create_vpc(self):

        self.vpc = ec2.create_vpc(
            CidrBlock=variables["VPCCidrBlock"],
            AmazonProvidedIpv6CidrBlock=False,
            DryRun=False,
            InstanceTenancy='default',
            TagSpecifications=[
                {
                    'ResourceType': 'vpc',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3_vpc'
                        },
                    ]
                },
            ]
        )
        return self.vpc


    #create_public_subnet
    def create_public_subnet(self):

        self.subnet = self.vpc.create_subnet(
            TagSpecifications=[
                {
                    'ResourceType': 'subnet',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3_subnet'
                        },
                    ]
                },
            ],
            AvailabilityZone=variables["SubnetAvailabilityZone"],
            CidrBlock=variables["SubnetCidrBlock"],
            DryRun=False,
            Ipv6Native=False
        )
        return self.subnet


    #create_internet_gateway
    def create_igw(self):

        self.internet_gateway = ec2.create_internet_gateway(
            TagSpecifications=[
                {
                    'ResourceType': 'internet-gateway',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3-igw'
                        },
                    ]
                },
            ],
            DryRun=False
        )
        return self.internet_gateway


    #attach_internet_gateway_to_vpc
    def attach_igw(self):

        response = self.vpc.attach_internet_gateway(
            DryRun=False,
            InternetGatewayId=f"{self.internet_gateway.id}",
        )
        return response


    #create_route_table
    def create_rt(self):

        self.route_table = self.vpc.create_route_table(
            DryRun=False,
            TagSpecifications=[
                {
                    'ResourceType': 'route-table',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3-rt'
                        },
                    ]
                },
            ]
        )
        return self.route_table


    #create route
    def create_route(self):

        route = client.create_route(
            DryRun=False,
            RouteTableId=f"{self.route_table.id}",
            DestinationCidrBlock=variables["RouteDestinationCidrBlock"],
            GatewayId=f"{self.internet_gateway.id}",
        )
        return route


    #create route table association
    def create_rt_association(self):

        response = client.associate_route_table(
            DryRun=False,
            RouteTableId=f"{self.route_table.id}",
            SubnetId=f"{self.subnet.id}",
        )
        return response


    #create master security group with rules
    def create_master_sg(self):

        self.security_group = self.vpc.create_security_group(
            GroupName='boto3_master_sg',
            Description='Security group for master ec2 instance',
            TagSpecifications=[
                {
                    'ResourceType': 'security-group',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3-master-sg'
                        },
                    ]
                },
            ]
        )

        client.authorize_security_group_ingress(
            GroupId=f"{self.security_group.id}",
            IpPermissions=[
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 22,
                    'ToPort': 22,
                    'IpRanges': [
                        {
                            'CidrIp': '0.0.0.0/0',
                            'Description': 'Allow SSH'
                        },
                    ]
                },
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 8086,
                    'ToPort': 8086,
                    'IpRanges': [
                        {
                            'CidrIp': '0.0.0.0/0',
                            'Description': 'Allow InfluxDB traffic'
                        },
                    ]
                },
            ]
        )
        return self.security_group


    #create master ec2 instance with public ip
    def create_master_ec2(self):

        self.response = client.run_instances(
            ImageId=variables["ec2ami"],
            MinCount=variables["ec2count"],
            MaxCount=variables["ec2count"],
            InstanceType=variables["ec2InstanceType"],
            KeyName=variables["ec2KeyName"],
            InstanceInitiatedShutdownBehavior='terminate',
            #UserData='#!/bin/bash\nsudo yum update -y\n',
            NetworkInterfaces=[
                {
                    'DeviceIndex': 0,
                    'SubnetId': f"{self.subnet.id}",
                    'Groups': [f"{self.security_group.id}"],
                    'AssociatePublicIpAddress': True
                },
                ],
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        {
                            'Key': 'Name',
                            'Value': 'boto3-master-ec2'
                        },
                    ]
                },
            ]

        )

        instance_id = self.response['Instances'][0]['InstanceId']
        client.get_waiter('instance_running').wait(InstanceIds=[instance_id])
        response = client.describe_instances(InstanceIds=[instance_id])
        public_ip = response['Reservations'][0]['Instances'][0]['PublicIpAddress']

        return instance_id, public_ip




"""creating = Create_resources()
print(creating.create_vpc())
print(creating.create_public_subnet())
print(creating.create_igw())
print(creating.attach_igw())
print(creating.create_rt())
print(creating.create_route())
print(creating.create_rt_association())
print(creating.create_master_sg())
print(creating.create_master_ec2())"""



class Destruction():

    def describe_resources(self):

        vpc = client.describe_vpcs(
            Filters=[{'Name': 'tag:Name', 'Values': ['boto3_vpc']}]
        )

        self.vpc_id = (vpc['Vpcs'][0]['VpcId'])

        print(self.vpc_id)

        ec2_instance = client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': ['boto3-master-ec2']}]
        )

        for reservation in ec2_instance['Reservations']:
            for instance in reservation['Instances']:
                self.instance_id = instance['InstanceId']

        print(self.instance_id)

    def destroy_resources(self):

        master_ec2 = client.terminate_instances(
            InstanceIds=[
                self.instance_id,
            ],
            DryRun=False
        )

        client.get_waiter('instance_terminated').wait(InstanceIds=[self.instance_id])

        print("boto3_master_ec2 was destroyed!")











        vpc = client.delete_vpc(
            VpcId=self.vpc_id,
            DryRun=False
        )

        print("boto3_vpc was destroyed!")






dest = Destruction()
dest.describe_resources()
#print(dest.destroy_resources())



"""class destroy_resources(Create_resources):
    # destroy ec2 instances
    def destroy_instances(self):
        response = client.terminate_instances(
            InstanceIds=[
                self.instance,
            ],
            DryRun=False
        )
        return response


    # destroy security groups
    def destroy_sgs(self):
        response = client.delete_security_group(
            GroupId=self.security_group,
            DryRun=False
        )
        return response


    #delete route tables
    def destroy_rts(self):
        response = client.delete_route_table(
            DryRun=False,
            RouteTableId=self.route_table
        )
        return response


    #delete internet gateway
    def destroy_igw(self):
        response = client.delete_internet_gateway(
            DryRun=True | False,
            InternetGatewayId='string'
        )
        return response


    #destroy subnet
    def destroy_subnet(self):
        response = client.delete_subnet(
            SubnetId=self.subnet,
            DryRun=False
        )
        return response


    #destroy vpc
    def destroy_vpc(self):
        response = client.delete_vpc(
            VpcId=self.vpc,
            DryRun=True | False
        )
        return response

"""

"""creating = Create_resources()
attrs = (getattr(creating, name) for name in dir(creating))
methods = filter(inspect.ismethod, attrs)
for method in methods:
    try:
        method()
    except TypeError:
        # Can't handle methods with required arguments.
        pass"""




"""class AutoScalingConfigSchema(Schema):
    class Meta:
        unknown = RAISE

    AutoScalingGroupName = fields.String()
    LaunchConfigurationName = fields.String()
    MaxSize = fields.Integer()
    MinSize = fields.Integer()
    DesiredCapacity = fields.Integer()
    TargetGroupARNs = fields.List(fields.String)
    VPCZoneIdentifier = fields.String()

def getAutoScalingGroupConfig(configDictionary):
    scalingConfig = AutoScalingConfigSchema().load(configDictionary)
    return scalingConfig

def getAutoScalingGroupConfigFromFile(fileName):
    with open(fileName) as json_file:
        return getAutoScalingGroupConfig(json.load(json_file))

def getAutoscalingGroupsByName(autoscalingClient, groupName):
    autoscalingGroups = autoscalingClient.describe_auto_scaling_groups()["AutoScalingGroups"]
    return list(filter(lambda group: group["AutoScalingGroupName"] == groupName,
                   autoscalingGroups))

scalingConfig = getAutoScalingGroupConfigFromFile("./dictionary.json")
filteredGroups = getAutoscalingGroupsByName(client, scalingConfig['AutoScalingGroupName'])

if len(filteredGroups) != 0:
    name = scalingConfig["AutoScalingGroupName"]
    logging.info(f"Group \"{name}\" already exists")
elif len(filteredGroups) == 0:

    response = client.create_auto_scaling_group(
        AutoScalingGroupName=scalingConfig["AutoScalingGroupName"],
        HealthCheckGracePeriod=300,
        HealthCheckType='ELB',
        LaunchConfigurationName=scalingConfig["LaunchConfigurationName"],
        MaxSize=scalingConfig["MaxSize"],
        MinSize=scalingConfig["MinSize"],
        DesiredCapacity=scalingConfig["DesiredCapacity"],
        TargetGroupARNs=scalingConfig["TargetGroupARNs"],
        VPCZoneIdentifier=scalingConfig["VPCZoneIdentifier"],
    )

    name = scalingConfig["AutoScalingGroupName"]
    logging.info(f"Group \"{name}\" successfully created")

asg = scalingConfig["AutoScalingGroupName"]

asg_response = client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg])

#print(asg_response)

instance_ids = []  # List to hold the instance-ids

for i in asg_response['AutoScalingGroups']:
    for k in i['Instances']:
        instance_ids.append(k['InstanceId'])

ec2_response = ec2_client.describe_instances(
         InstanceIds=instance_ids
         )

print(instance_ids)  # This line will print the instance_ids

private_ip = []  # List to hold the Private IP Address

if instance_ids == []:
    logging.info("No running instances")
else:
   for instances in ec2_response['Reservations']:
    for ip in instances['Instances']:
       private_ip.append(ip['PrivateIpAddress'])

    #instance_ips = ("\n".join(private_ip))

    instance_ips = (private_ip)

    for format in instance_ips:
      s = (format.split("."))
      formatted = (f"ip-{s[0]}-{s[1]}-{s[2]}-{s[3]}")
      logging.info(f"Instance Ip: {formatted}")"""
