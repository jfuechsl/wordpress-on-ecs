variable "aws_region" {}

variable "availability_zones" {
  type = "list"
}

variable "ecs_cluster_instance_type" {}
variable "rds_instance_type" {}
variable "asg_min_size" {}
variable "asg_desired_capacity" {}
variable "asg_max_size" {}
variable "wordpress_repo_name" {}
variable "aws_profile" {}
variable "wp_db_name" {}
variable "wp_db_username" {}
variable "wp_db_password" {}
variable "wp_db_charset" {}
variable "wp_db_collate" {}
variable "wp_auth_key" {}
variable "wp_secure_auth_key" {}
variable "wp_logged_in_key" {}
variable "wp_nonce_key" {}
variable "wp_auth_salt" {}
variable "wp_secure_auth_salt" {}
variable "wp_logged_in_salt" {}
variable "wp_nonce_salt" {}
variable "wp_table_prefix" {}
