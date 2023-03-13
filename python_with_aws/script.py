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
                            'Value': 'boto3_igw'
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
                            'Value': 'boto3_rt'
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
                            'Value': 'boto3_master_sg'
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
                            'Value': 'boto3_master_ec2'
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




creating = Create_resources()
print(creating.create_vpc())
print(creating.create_public_subnet())
print(creating.create_igw())
print(creating.attach_igw())
print(creating.create_rt())
print(creating.create_route())
print(creating.create_rt_association())
print(creating.create_master_sg())
print(creating.create_master_ec2())



class Destruction():

    def describe_resources(self):

        self.master_sg = client.describe_security_groups(Filters=[{'Name': 'tag:Name', 'Values': ['boto3_master_sg']}])

        for group in self.master_sg['SecurityGroups']:
            self.group_id = group['GroupId']
            self.group_name = group['GroupName']
            print(f"Security Group ID: {self.group_id}, Name: {self.group_name}")


        self.master_rt = client.describe_route_tables(Filters=[{'Name': 'tag:Name', 'Values': ['boto3_rt']}])

        for route_table in self.master_rt['RouteTables']:
            self.route_table_id = route_table['RouteTableId']
            print(f"Route Table ID: {self.route_table_id}")


        self.master_igw = client.describe_internet_gateways(Filters=[{'Name': 'tag:Name', 'Values': ['boto3_igw']}])

        for gateway in self.master_igw['InternetGateways']:
            self.gateway_id = gateway['InternetGatewayId']
            print(f"Internet Gateway ID: {self.gateway_id}")


        public_subnet = client.describe_subnets(Filters=[{'Name': 'tag:Name', 'Values': ['boto3_subnet']}])

        for subnet in public_subnet['Subnets']:
            self.subnet_id = subnet['SubnetId']
            print(f"Subnet ID: {self.subnet_id}")


        vpc = client.describe_vpcs(
            Filters=[{'Name': 'tag:Name', 'Values': ['boto3_vpc']}]
        )

        self.vpc_id = (vpc['Vpcs'][0]['VpcId'])

        print(f"VPC ID: {self.vpc_id}")

        ec2_instance = client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': ['boto3_master_ec2']}]
        )

        for reservation in ec2_instance['Reservations']:
            for instance in reservation['Instances']:
                self.instance_id = instance['InstanceId']

        print(f"Master instance ID: {self.instance_id}")



    def destroy_resources(self):


        master_ec2 = client.terminate_instances(
            InstanceIds=[
                self.instance_id,
            ],
            DryRun=False
        )

        client.get_waiter('instance_terminated').wait(InstanceIds=[self.instance_id])

        print("boto3_master_ec2 was deleted!")


        for rtb in self.master_rt['RouteTables']:
            for association in rtb['Associations']:
                if not association['Main']:
                    client.disassociate_route_table(AssociationId=association['RouteTableAssociationId'])

        for rtb in self.master_rt['RouteTables']:
            for route in rtb['Routes']:
                if route['Origin'] != 'CreateRouteTable':
                    client.delete_route(RouteTableId=rtb['RouteTableId'], DestinationCidrBlock=route['DestinationCidrBlock'])

        for rtb in self.master_rt['RouteTables']:
            client.delete_route_table(RouteTableId=rtb['RouteTableId'])

        print("master_rt was deleted!")


        for igw in self.master_igw['InternetGateways']:
            for attachment in igw['Attachments']:
                client.detach_internet_gateway(InternetGatewayId=igw['InternetGatewayId'],
                                                   VpcId=attachment['VpcId'])

        for igw in self.master_igw['InternetGateways']:
            client.delete_internet_gateway(InternetGatewayId=igw['InternetGatewayId'])

        print("master_igw was deleted!")


        public_subnet = client.delete_subnet(
            SubnetId=self.subnet_id,
            DryRun=False
        )

        print("public_subnet was deleted!")


        for sg in self.master_sg['SecurityGroups']:
            for ip_permission in sg['IpPermissions']:
                client.revoke_security_group_ingress(GroupId=sg['GroupId'], IpPermissions=[ip_permission])
            for ip_permission in sg['IpPermissionsEgress']:
                client.revoke_security_group_egress(GroupId=sg['GroupId'], IpPermissions=[ip_permission])

        for sg in self.master_sg['SecurityGroups']:
                client.delete_security_group(GroupId=sg['GroupId'])

        print("master_sg was deleted!")


        vpc = client.delete_vpc(
            VpcId=self.vpc_id,
            DryRun=False
        )

        return "boto3_vpc with all dependencies was destroyed!"






dest = Destruction()
dest.describe_resources()
print(dest.destroy_resources())









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
