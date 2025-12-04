data "aws_route53_zone" "selected_zone" {
  name         = var.domain_name
  private_zone = false
}