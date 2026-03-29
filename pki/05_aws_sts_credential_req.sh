#!/usr/bin/env bash

# See https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html
# See https://github.com/aws/rolesanywhere-credential-helper/releases/tag/v1.8.0

cd /tmp
curl -sLO https://rolesanywhere.amazonaws.com/releases/1.8.0/X86_64/Linux/Amzn2023/aws_signing_helper
mv /tmp/aws_signing_helper /usr/local/bin/aws_signing_helper
sudo chmod 744 /usr/local/bin/aws_signing_helper

sudo tee ~/.aws/config > /dev/null << CONFIG
[profile hetzner-pki]
credential_process = /usr/local/bin/aws_signing_helper credential-process \
  --certificate /etc/pki/iam-anywhere/end-entity-cert.pem \
  --private-key /etc/pki/iam-anywhere/end-entity-key \
  --trust-anchor-arn arn:aws:rolesanywhere:eu-central-1:010928217051:trust-anchor/c3c0f28b-7779-4acb-b698-87e72a46b9db \
  --profile-arn arn:aws:rolesanywhere:eu-central-1:010928217051:profile/f0e050f8-2e78-411d-8c39-a2938475fbf5 \
  --role-arn arn:aws:iam::010928217051:role/HetznerPKI-Secret-Retrieval-Role
region = eu-central-1
CONFIG

export ENV_FILE_SECRET_ID="fiscalismia-backend/.env"
export AWS_PROFILE="hetzner-pki"
aws secretsmanager get-secret-value \
  --profile hetzner-pki \
  --secret-id $ENV_FILE_SECRET_ID \
  --region eu-central-1 \
  --output text \
  --query SecretString \
  >> /tmp/.env

cat /tmp/.env
shred -vzf -n 5 /tmp/.env