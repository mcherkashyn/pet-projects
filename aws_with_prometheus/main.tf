provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "tf_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "tf_vpc"
    Terraform = "true"
  }
}


resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "tf_public_subnet"
    Terraform = "true"
  }
}


resource "aws_subnet" "tf_public_subnet_2" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "tf_public_subnet_2"
    Terraform = "true"
  }
}


resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_igw"
    Terraform = "true"
  }
}


resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }

  tags = {
    Name = "tf_public_route_table"
    Terraform = "true"
  }
}


resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.tf_public_subnet.id
  route_table_id = aws_route_table.tf_public_route_table.id
}


resource "aws_route_table_association" "route_table_association_2" {
  subnet_id      = aws_subnet.tf_public_subnet_2.id
  route_table_id = aws_route_table.tf_public_route_table.id
}


resource "aws_security_group" "tf_monitoring_master_sg" {
  name = "tf_monitoring_master_sg"

    ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 9090
        to_port         = 9090
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 9100
        to_port         = 9100
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_monitoring_master_sg"
  }
}


resource "aws_security_group" "tf_monitoring_asg_sg" {
  name = "tf_monitoring_asg_sg"

    ingress {
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 9090
        to_port         = 9090
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 9100
        to_port         = 9100
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_monitoring_asg_sg"
  }
}


resource "aws_instance" "tf_monitoring_master" {
  ami = var.settings.ec2_instance.ami
  instance_type = var.settings.ec2_instance.instance_type
  key_name = var.settings.ec2_instance.key_name
  security_groups = [aws_security_group.tf_monitoring_master_sg.id]
  subnet_id = aws_subnet.tf_public_subnet.id
  user_data = <<EOF
#!/bin/bash

#install node_exporter
sudo apt-get update
sudo echo 'GatewayPorts yes' | sudo tee --append /etc/ssh/sshd_config
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
sudo tar -xf node_exporter-1.5.0.linux-amd64.tar.gz
sudo mv node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin
sudo rm -r node_exporter-1.5.0.linux-amd64*
sudo useradd -rs /bin/false node_exporter
sudo touch /etc/systemd/system/node_exporter.service
sudo echo '[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

#install Prometheus
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.37.6/prometheus-2.37.6.linux-amd64.tar.gz
sudo tar -xf prometheus-2.37.6.linux-amd64.tar.gz
sudo mv prometheus-2.37.6.linux-amd64/prometheus prometheus-2.37.6.linux-amd64/promtool /usr/local/bin
sudo mkdir /etc/prometheus /var/lib/prometheus
sudo mv prometheus-2.37.6.linux-amd64/consoles prometheus-2.37.6.linux-amd64/console_libraries /etc/prometheus
sudo rm -r prometheus-2.37.6.linux-amd64*
sudo touch /etc/prometheus/prometheus.yml
sudo echo 'global:
  scrape_interval: 10s
scrape_configs:
  - job_name: node-exporter
    scrape_interval: 5s
    ec2_sd_configs:
     - region: us-east-1
       access_key: "${var.access_key}"
       secret_key: "${var.secret_key}"
       port: 9100
       filters:
          - name: tag:Name
            values:
              - tf_monitoring_master
              - tf_monitoring_asg
    relabel_configs:
        - source_labels: [__meta_ec2_private_ip]
          target_label: instance
        - source_labels: [__meta_ec2_tag_Name]
          target_label: instance_name' | sudo tee /etc/prometheus/prometheus.yml
sudo useradd -rs /bin/false prometheus
sudo chown -R prometheus: /etc/prometheus /var/lib/prometheus
sudo touch /etc/systemd/system/prometheus.service
sudo echo '[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

#install Grafana
sudo wget https://dl.grafana.com/oss/release/grafana_9.4.7_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_9.4.7_amd64.deb
sudo systemctl daemon-reload && sudo systemctl enable grafana-server && sudo systemctl start grafana-server.service
EOF

  tags = {
    Name = "tf_monitoring_master"
    Terraform = "true"
  }
}


resource "aws_eip" "tf_monitoring_master_eip" {
  instance = aws_instance.tf_monitoring_master.id
  vpc = true

  tags = {
    Name = "tf_monitoring_master_eip"
  }
}


resource "aws_launch_configuration" "tf_monitoring_lc" {
  name_prefix     = "tf_monitoring_lc"
  image_id        = var.settings.ec2_instance.ami
  instance_type   = var.settings.ec2_instance.instance_type
  user_data       = file("user_data_slave.sh")
  security_groups = [aws_security_group.tf_monitoring_asg_sg.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "tf_monitoring_asg" {
    min_size             = 1
    max_size             = 3
    desired_capacity     = 2
    launch_configuration = aws_launch_configuration.tf_monitoring_lc.name
    vpc_zone_identifier  = [aws_subnet.tf_public_subnet.id, aws_subnet.tf_public_subnet_2.id]
    
    tag {
        key                 = "Name"
        value               = "tf_monitoring_asg"
        propagate_at_launch = true
    }

    depends_on = [aws_instance.tf_monitoring_master]
}
