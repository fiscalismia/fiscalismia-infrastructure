#!/usr/bin/env bash

# See https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html
# See https://github.com/aws/rolesanywhere-credential-helper/releases/tag/v1.8.0

################################ INFO ########################################################################################
# PARAM $1 the arn:aws:rolesanywhere:region-account-id:trust-anchor/id
# PARAM $2 the arn:aws:rolesanywhere:region-account-id:profile/id
# PARAM $3 the arn:aws:iam::account-id:role/rolename
# PARAM $4 is the id of the secret containing the .env file in eu-central-1 region
# e.g. ./scripts/05_aws_sts_credential_req.sh arn:aws:rolesanywhere:eu-central-1:010928217051:trust-anchor/c3c0f28b-7779-4acb-b698-87e72a46b9db arn:aws:rolesanywhere:eu-central-1:010928217051:profile/f0e050f8-2e78-411d-8c39-a2938475fbf5 arn:aws:iam::010928217051:role/HetznerPKI-Secret-Retrieval-Role fiscalismia-backend/.env
##############################################################################################################################

export LEAF_CERT="/etc/pki/iam-anywhere/end-entity-cert.pem"
export LEAF_KEY="/etc/pki/iam-anywhere/end-entity-key"
export TRUST_ANCHOR_ARN="$1"
export PROFILE_ARN="$2"
export ROLE_ARN="$3"
export SECRET_ID="$4"

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <TRUST_ANCHOR_ARN> <PROFILE_ARN> <ROLE_ARN> <SECRET_ID>"
    exit 1
fi

if [[ -f "/usr/local/bin/aws_signing_helper" ]]; then
  echo "aws_signing_helper binary pre-installed at $(command -v aws_signing_helper)"
else
  echo "aws_signing_helper binary not installed."
  exit 1
fi

sudo tee ~/.aws/config > /dev/null << CONFIG
[profile hetzner-pki]
credential_process = /usr/local/bin/aws_signing_helper credential-process \
  --certificate $LEAF_CERT \
  --private-key $LEAF_KEY \
  --trust-anchor-arn $TRUST_ANCHOR_ARN \
  --profile-arn $PROFILE_ARN \
  --role-arn $ROLE_ARN
region = eu-central-1
CONFIG

# Query .env secret from AWS with temporary STS credentials
set -euo pipefail
export AWS_PROFILE="hetzner-pki"
aws secretsmanager get-secret-value \
  --profile $AWS_PROFILE \
  --secret-id $SECRET_ID \
  --region eu-central-1 \
  --output text \
  --query SecretString \
  >> /tmp/.env

# TEMPORARY .env setup to be changed
cp /tmp.env /usr/local/etc/fiscalismia-demo/.env
chmod 400 /usr/local/etc/fiscalismia-demo/.env
shred -vzf -n 5 /tmp/.env
rm -f /tmp/.env
