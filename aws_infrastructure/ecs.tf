resource "aws_ecs_cluster" "demo_cluster" {
  name = "demo-cluster"
}

data "template_file" "wordpress_container_definitions" {
  template = "${file("container-definitions/wordpress.json")}"

  depends_on = ["aws_db_instance.wordpress"]

  vars {
    aws_region              = "${var.aws_region}"
    wordpress_ecr_image_uri = "${aws_ecr_repository.wordpress.repository_url}"
    wordpress_ecr_image_tag = "latest"
    wp_db_name              = "${var.wp_db_name}"
    wp_db_user              = "${var.wp_db_username}"
    wp_db_password          = "${var.wp_db_password}"
    wp_db_host              = "${aws_db_instance.wordpress.address}"
    wp_db_charset           = "${var.wp_db_charset}"
    wp_db_collate           = "${var.wp_db_collate}"
    wp_auth_key             = "${var.wp_auth_key}"
    wp_secure_auth_key      = "${var.wp_secure_auth_key}"
    wp_logged_in_key        = "${var.wp_logged_in_key}"
    wp_nonce_key            = "${var.wp_nonce_key}"
    wp_auth_salt            = "${var.wp_auth_salt}"
    wp_secure_auth_salt     = "${var.wp_secure_auth_salt}"
    wp_logged_in_salt       = "${var.wp_logged_in_salt}"
    wp_nonce_salt           = "${var.wp_nonce_salt}"
    wp_table_prefix         = "${var.wp_table_prefix}"
  }
}

resource "aws_cloudwatch_log_group" "wordpress_logs" {
  name = "wordpress-logs"
}

resource "aws_ecs_task_definition" "wordpress" {
  family                = "wordpress"
  container_definitions = "${data.template_file.wordpress_container_definitions.rendered}"

  volume {
    name = "www-data"
  }
}

resource "aws_ecs_service" "wordpress" {
  name            = "wordpress"
  cluster         = "${aws_ecs_cluster.demo_cluster.id}"
  task_definition = "${aws_ecs_task_definition.wordpress.arn}"
  desired_count   = 1

  iam_role   = "${aws_iam_role.ecs_service_role.arn}"
  depends_on = ["aws_iam_role.ecs_service_role"]

  load_balancer {
    target_group_arn = "${aws_lb_target_group.wordpress.arn}"
    container_name   = "wordpress"
    container_port   = 80
  }
}

resource "aws_lb_listener" "ecs_alb_http_listener" {
  load_balancer_arn = "${aws_lb.ecs_load_balancer.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.wordpress.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-service-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}
