# IAM User: Terraform Backend for AinAC Hetzner Infrastructure
resource "aws_iam_user" "terraform_ainac_backend_hcloud" {
  name = "terraform-backend-hcloud"
  path = "/service-accounts/"
  tags = {
    purpose = "Terraform S3 backend for Hetzner infrastructure"
  }
}

resource "aws_iam_access_key" "terraform_ainac_backend_hcloud" {
  user = aws_iam_user.terraform_ainac_backend_hcloud.name
}

# IAM Policy: least-privilege S3 backend access
data "aws_iam_policy_document" "terraform_backend_s3_access" {

  statement {
    sid     = "AllowStateBucketListing"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.s3_ainac_terraform_backend.bucket_arn
    ]
  }

  statement {
    sid    = "AllowStateFileReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.s3_ainac_terraform_backend.bucket_arn}/AinAC-infrastructure/hcloud/*"
    ]
  }
}

resource "aws_iam_user_policy" "terraform_ainac_backend_hcloud" {
  name   = "terraform-backend-s3-state-access"
  user   = aws_iam_user.terraform_ainac_backend_hcloud.name
  policy = data.aws_iam_policy_document.terraform_backend_s3_access.json
}

# Outputs: retrieve credentials via `terraform output`
output "terraform_ainac_backend_hcloud_access_key_id" {
  description = "Access Key ID for the Hetzner Terraform backend user"
  value       = aws_iam_access_key.terraform_ainac_backend_hcloud.id
  sensitive   = true
}

output "terraform_ainac_backend_hcloud_secret_access_key" {
  description = "Secret Access Key for the Hetzner Terraform backend user"
  value       = aws_iam_access_key.terraform_ainac_backend_hcloud.secret
  sensitive   = true
}