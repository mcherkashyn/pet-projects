#!/bin/bash
sudo apt-get update
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
  - job_name: 'prometheus_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']' | sudo tee /etc/prometheus/prometheus.yml


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


sudo wget https://dl.grafana.com/oss/release/grafana_9.4.7_amd64.deb
sudo apt-get install -y adduser libfontconfig
sudo dpkg -i grafana_9.4.7_amd64.deb
sudo systemctl daemon-reload && sudo systemctl enable grafana-server && sudo systemctl start grafana-server.service





global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'node-exporter'
    scrape_interval: 5s
    ec2_sd_configs:
     - region: 'us-east-1'
       role_arn: 'arn:aws:iam::772320319753:role/prometheusEc2Role'
         
       filters:
          - name: tag:Name
            values:
              - tf_monitoring_asg
    relabel_configs:
        - source_labels: [__meta_ec2_tag_Name]
          target_label: instance
        - source_labels: [__address__]
          target_label: __address__
          replacement: $1:9100
          regex: (.+):.*:9100










# global:
#   scrape_interval: 10s

# scrape_configs:
#   - job_name: prometheus_metrics
#     scrape_interval: 5s
#     static_configs:
#       - targets: ['localhost:9090']

#   - job_name: nodes-dev
#     scrape_interval: 5s
#     ec2_sd_configs:
#       - region: us-east-1
#         port: 9100
#     relabel_configs:
#     # Only monitor instances with a Name starting with "tf_monitoring"
#       - source_labels: [__meta_ec2_tag_Name]
#         regex: tf_monitoring.*
#         action: keep
#       - source_labels: [__meta_ec2_tag_Name,__meta_ec2_availability_zone]
#         target_label: instance
