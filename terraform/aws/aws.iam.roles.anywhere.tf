# See https://docs.aws.amazon.com/rolesanywhere/latest/userguide/getting-started.html
# See https://docs.aws.amazon.com/rolesanywhere/latest/userguide/authentication.html
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rolesanywhere_trust_anchor
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rolesanywhere_profile
# See https://dev.to/gerson_morales_3e89188d50/setting-up-iam-anywhere-using-terraform-3nf

resource "aws_rolesanywhere_trust_anchor" "pki_roles_anywhere_secret_manager" {
  name    = "HetznerPKI-Secret-Retrieval-TrustAnchor"
  enabled = true
  source {
    source_data {
      # We can either add the certificate bundle of root + intermediate
      # Or for better security posture, only the public cert of the intermediate
      x509_certificate_data = file("${path.module}/certificates/PrivateCA.pem")
    }
    source_type = "CERTIFICATE_BUNDLE"
  }
  notification_settings {
    enabled   = true
    event     = "CA_CERTIFICATE_EXPIRY"
    threshold = 30  # days before expiry
    channel   = "ALL"
  }
}

resource "aws_rolesanywhere_profile" "pki_roles_anywhere_secret_manager" {
  enabled             = true
  name                = "HetznerPKI-Secret-Retrieval-Profile"
  role_arns           = [aws_iam_role.pki_roles_anywhere_secret_manager.arn]
  duration_seconds    = 900
}

resource "aws_iam_role" "pki_roles_anywhere_secret_manager" {
  name = "HetznerPKI-Secret-Retrieval-Role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "rolesanywhere.amazonaws.com",
        },
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
          "sts:SetSourceIdentity"
        ],
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:rolesanywhere:${var.region}:${data.aws_caller_identity.current.account_id}:trust-anchor/${aws_rolesanywhere_trust_anchor.pki_roles_anywhere_secret_manager.id}"

          }
          StringEquals = {
            "aws:PrincipalTag/x509Subject/CN" = "Fiscalismia End Entity"
          }
        }
      }
    ]
  })
}

# Permission policies in the role of iamanywhere-trust-role
resource "aws_iam_policy" "pki_roles_anywhere_secret_manager_access" {
  name        = "HetznerPKI-Secret-Retrieval-Policy"
  path        = "/"
  description = "Allows retrieval of secrets to Hetzner servers authenticated via X.509 PKIs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-backend/.env*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pki_roles_anywhere_secret_manager_access" {
  role       = aws_iam_role.pki_roles_anywhere_secret_manager.name
  policy_arn = aws_iam_policy.pki_roles_anywhere_secret_manager_access.arn
}
