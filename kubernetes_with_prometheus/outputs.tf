output region {
  value = var.aws_region
}

output elb_dns_name {
  value = "http://${aws_alb.alb.dns_name}"
}

output "endpoint" {
  value = aws_eks_cluster.tf-eks-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.tf-eks-cluster.certificate_authority[0].data
}
