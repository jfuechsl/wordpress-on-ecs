resource "aws_ecr_repository" "wordpress" {
  name = "${var.wordpress_repo_name}"
}

output "wordpress_repo" {
  value = "${aws_ecr_repository.wordpress.repository_url}"
}
