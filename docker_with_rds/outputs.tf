output "ec2_public_ip" {
    description = "The public IP address of the ec2 instance"
    value = aws_eip.tf_eip[0].public_ip
    depends_on = [aws_eip.tf_eip]
}

output "ec2_public_dns" {
    description = "The public DNS address of the web server"
    value = aws_eip.tf_eip[0].public_dns
    depends_on = [aws_eip.tf_eip]
}

output "database_endpoint" {
    description = "The endpoint of the database"
    value = aws_db_instance.tf_rds.address
}

output "log_group" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${aws_cloudwatch_log_group.flask_logs.name}"
}
