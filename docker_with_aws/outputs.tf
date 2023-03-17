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
