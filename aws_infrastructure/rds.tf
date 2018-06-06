resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_instance_sg.id}"]
  }
}

resource "aws_db_subnet_group" "rds_sng" {
  name = "rds-subnet-group"

  subnet_ids = ["${aws_subnet.psn.*.id}"]
}

resource "aws_db_instance" "wordpress" {
  name              = "${var.wp_db_name}"
  allocated_storage = 5
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "${var.rds_instance_type}"
  username          = "${var.wp_db_username}"
  password          = "${var.wp_db_password}"

  db_subnet_group_name   = "${aws_db_subnet_group.rds_sng.name}"
  vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]

  skip_final_snapshot = true
}

output "wordpress_db_endpoint" {
  value = "${aws_db_instance.wordpress.endpoint}"
}
