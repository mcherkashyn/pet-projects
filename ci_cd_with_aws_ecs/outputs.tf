output region {
  value = var.aws_region
}

output ecr_image {
  value = var.ecr_image
}

output elb_dns_name {
  value = "http://${aws_alb.alb.dns_name}"
}

output log_group {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${aws_cloudwatch_log_group.log_group.name}"
}
