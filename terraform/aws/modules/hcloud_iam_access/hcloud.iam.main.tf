
##################### HCLOUD DNS TLS RENEWAL ROLE FOR ACCESS KEYS ON SERVER ENDPOINTS #####################
data "aws_iam_policy_document" "hcloud_certbot_dns_tls_access" {
  statement {
    sid       = "ListRoute53HostedZones"
    effect    = "Allow"
    actions   = [
      "route53:ListHostedZones",
      "route53:GetChange"]
    resources = ["*"]
  }

  statement {
    sid       = "ChangeRoute53HostedZoneRecords"
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected_zone.id}"]
  }
}
resource "aws_iam_policy" "hcloud_certbot_dns_tls_access" {
  name        = "HcloudCertbotDnsTlsRenewalPolicy"
  description = "Allow Hcloud Server to Renew TLS Certificates via Certbot"
  policy      = data.aws_iam_policy_document.hcloud_certbot_dns_tls_access.json
}

resource "aws_iam_user_policy_attachment" "hcloud_certbot_dns_tls_access" {
  user       = aws_iam_user.hcloud_certbot_dns_tls_cert_renewal.name
  policy_arn = aws_iam_policy.hcloud_certbot_dns_tls_access.arn
}

resource "aws_iam_user" "hcloud_certbot_dns_tls_cert_renewal" {
  name = "HcloudCertbot-TLSCertificateRenewal-Role"
  path = "/"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_access_key" "hcloud_certbot_dns_tls_cert_renewal" {
  user    = aws_iam_user.hcloud_certbot_dns_tls_cert_renewal.name
  lifecycle {
    prevent_destroy = true
  }
}

output "secret_key" {
  value = aws_iam_access_key.hcloud_certbot_dns_tls_cert_renewal.secret
}

output "access_key_id" {
  value = aws_iam_access_key.hcloud_certbot_dns_tls_cert_renewal.id
}