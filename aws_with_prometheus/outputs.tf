output "prometheus_ip" {
    description = "The public IP address of Prometheus"
    value = "${aws_eip.tf_monitoring_master_eip[0].public_ip}:9090"
    depends_on = [aws_eip.tf_monitoring_master_eip[0]]
}

output "grafana_ip" {
    description = "The public IP address of Grafana"
    value = "${aws_eip.tf_monitoring_master_eip[0].public_ip}:3000"
    depends_on = [aws_eip.tf_monitoring_master_eip[0]]
}
