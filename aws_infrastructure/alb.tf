resource "aws_lb" "ecs_load_balancer" {
  name               = "ecs-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_sg.id}"]
  subnets            = ["${aws_subnet.psn.*.id}"]
}

output "load_balancer_dns_name" {
  value = "${aws_lb.ecs_load_balancer.dns_name}"
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "alb_sg_ecs_instance_egress" {
  security_group_id        = "${aws_security_group.alb_sg.id}"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.ecs_instance_sg.id}"
}
