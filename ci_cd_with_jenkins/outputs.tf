output "ec2_public_dns" {
    description = "The public DNS address of the ec2 instance"
    value = aws_eip.tf_ec2_eip[0].public_dns
}

output "ec2_public_ip" {
    description = "The public IP address of the ec2 instance"
    value = aws_eip.tf_ec2_eip[0].public_ip
}
