output "ec2_public_ip" {
    description = "The public IP address of the ec2 instance"
    value = aws_eip.tf-eip[0].public_ip
    depends_on = [aws_eip.tf-eip]
}

output "ec2_public_dns" {
    description = "The public DNS address of the web server"
    value = aws_eip.tf-eip[0].public_dns
    depends_on = [aws_eip.tf-eip]
}

output "database_endpoint" {
    description = "The endpoint of the database"
    value = aws_db_instance.tf-rds.address
}

output "database_port" {
    description = "The port of the database"
    value = aws_db_instance.tf-rds.port
}
