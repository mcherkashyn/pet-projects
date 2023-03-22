output project_name {
  value = var.project_name
}

output region {
  value = var.aws_region
}

output ecr_image {
  value = var.ecr_image
}

output alb_dns_name {
  value = "http://${aws_alb.alb.dns_name}"
}

output security_group_alb {
  value = aws_security_group.alb.id
}

output security_group_ecs_tasks {
  value = aws_security_group.ecs_tasks.id
}

output log_group {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${aws_cloudwatch_log_group.log_group.name}"
}
