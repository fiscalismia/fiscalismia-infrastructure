#        ___           ___          __        ___  __
#  |__| |__   /\  |     |  |__|    /  ` |__| |__  /  ` |__/
#  |  | |___ /~~\ |___  |  |  |    \__, |  | |___ \__, |  \
resource "aws_route53_health_check" "root_domain_http_reachable" {
  fqdn              = var.domain_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "root_domain_https_reachable" {
  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "demo_domain_http_reachable" {
  fqdn              = "${var.demo_subdomain}.${var.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "demo_domain_https_reachable" {
  fqdn              = "${var.demo_subdomain}.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "demo_backend_domain_http_reachable" {
  fqdn              = "${var.demo_backend_subdomains}.${var.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "demo_backend_domain_https_reachable" {
  fqdn              = "${var.demo_backend_subdomains}.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "backend_domain_http_reachable" {
  fqdn              = "${var.backend_subdomain}.${var.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "backend_domain_https_reachable" {
  fqdn              = "${var.backend_subdomain}.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "monitoring_domain_http_reachable" {
  fqdn              = "${var.monitoring_subdomain}.${var.domain_name}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_route53_health_check" "monitoring_domain_https_reachable" {
  fqdn              = "${var.monitoring_subdomain}.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}