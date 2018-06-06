data "aws_ami" "aws_linux_ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "ecs_instance_sg" {
  name   = "ecs-instance-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs_instance_rds_egress" {
  security_group_id        = "${aws_security_group.ecs_instance_sg.id}"
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.rds_sg.id}"
}

resource "aws_launch_configuration" "ecs_instance_lc" {
  name                 = "ecs-instance-launch-configuration"
  image_id             = "${data.aws_ami.aws_linux_ecs.image_id}"
  instance_type        = "${var.ecs_cluster_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance_profile.id}"

  root_block_device {
    volume_type           = "standard"
    volume_size           = 25
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups             = ["${aws_security_group.ecs_instance_sg.id}"]
  associate_public_ip_address = true

  user_data = <<USERDATA
  #!/bin/bash
  echo ECS_CLUSTER=${aws_ecs_cluster.demo_cluster.name} >> /etc/ecs/ecs.config
  echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"] >> /etc/ecs/ecs.config
  USERDATA
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "ecs-auto-scaling-group"
  max_size             = "${var.asg_max_size}"
  min_size             = "${var.asg_min_size}"
  desired_capacity     = "${var.asg_desired_capacity}"
  vpc_zone_identifier  = ["${aws_subnet.psn.*.id}"]
  launch_configuration = "${aws_launch_configuration.ecs_instance_lc.name}"
  health_check_type    = "ELB"
}
