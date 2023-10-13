module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.1.0"

  # Autoscaling group
  name                      = var.slave_asg
  min_size                  = 0
  max_size                  = 3
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  user_data                 = base64encode(file("user_data_slave.sh"))

  # Launch template
  launch_template_name        = var.lt
  launch_template_description = "Launch template"
  security_groups             = [module.ec2_sg.security_group_id]
  image_id                    = var.ami
  instance_type               = var.instance_type
  enable_monitoring           = false

  tags = {
    Name      = var.slave_asg
    Terraform = "true"
  }
}
