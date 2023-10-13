module "master_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name                        = var.master_ec2
  instance_type               = var.instance_type
  ami                         = var.ami
  vpc_security_group_ids      = [module.ec2_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data = <<-EOF
      #!/bin/bash

      #install Prometheus
      sudo apt-get update
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
                    - "${var.slave_asg}"
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
    Name      = var.master_ec2
    Terraform = "true"
  }
}
