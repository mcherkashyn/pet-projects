output "prometheus_ip" {
    description = "The public IP address of Prometheus"
    value = "${module.master_ec2_instance.public_ip}:9090"
}

output "grafana_ip" {
    description = "The public IP address of Grafana"
    value = "${module.master_ec2_instance.public_ip}:3000"
}
