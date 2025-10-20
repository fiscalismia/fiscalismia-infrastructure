output "tls_certificate" {
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}