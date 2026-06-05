#!/usr/bin/env bash

# See https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html
# See https://github.com/aws/rolesanywhere-credential-helper/releases/tag/v1.8.0

################################ INFO ########################################################################################
# PARAM $1 the arn:aws:rolesanywhere:region-account-id:trust-anchor/id
# PARAM $2 the arn:aws:rolesanywhere:region-account-id:profile/id
# PARAM $3 the arn:aws:iam::account-id:role/rolename
# PARAM $4 is the id of the secret containing the .env file in eu-central-1 region
# PARAM $5 environment specific variable for conditional deployment on e.g. only demo instance
# e.g. ./scripts/05_aws_sts_credential_req.sh arn:aws:rolesanywhere:eu-central-1:010928217051:trust-anchor/c3c0f28b-7779-4acb-b698-87e72a46b9db arn:aws:rolesanywhere:eu-central-1:010928217051:profile/f0e050f8-2e78-411d-8c39-a2938475fbf5 arn:aws:iam::010928217051:role/HetznerPKI-Secret-Retrieval-Role fiscalismia-backend/.env demo
##############################################################################################################################

LEAF_CERT="/etc/pki/iam-anywhere/end-entity-cert.pem"
LEAF_KEY="/etc/pki/iam-anywhere/end-entity-key"
TRUST_ANCHOR_ARN="$1"
PROFILE_ARN="$2"
ROLE_ARN="$3"
SECRET_ID="$4"
TARGET_ENV="$5"

# temporary secret files to mount, load, then shred and remove
BACKEND_SECRET="backend.env"
WEBSCRAPER_SECRET="webscraper.env"
POSTGRES_SECRET="postgres_password"
ADMIN_SECRET="admin_password"

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]] || [[ -z "$5" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <TRUST_ANCHOR_ARN> <PROFILE_ARN> <ROLE_ARN> <SECRET_ID> <TARGET_ENV>"
    exit 1
fi

if [[ -f "/usr/local/bin/aws_signing_helper" ]]; then
  echo "aws_signing_helper binary pre-installed at $(command -v aws_signing_helper)"
else
  echo "aws_signing_helper binary not installed."
  exit 1
fi

echo "Setting up ~/.aws/config for short-lived credential process"
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

echo "ensuring aws credential-process issues short lived credentials:"
AWS_PROFILE="hetzner-pki"
aws sts get-caller-identity --profile hetzner-pki

# Setup RAM-backed tmpfs without swap possibility to avoid .env ever touching disk
SECRET_RAM_DIR="/usr/local/etc/fiscalismia-demo/secrets"
if ! mountpoint -q "$SECRET_RAM_DIR" 2>/dev/null; then
  echo "Mountpoint not detected for secret fs in RAM. Mounting..."
  mkdir -p $SECRET_RAM_DIR
  sudo mount -t tmpfs -o size=1m,mode=0700,noexec,nosuid,nodev,noswap tmpfs $SECRET_RAM_DIR
else
  echo "Mountpoint detected for secret fs in RAM."
fi

# Query .env secret from AWS with temporary STS credentials and write to RAM tmpfs
aws secretsmanager get-secret-value \
  --profile hetzner-pki \
  --secret-id $SECRET_ID \
  --region eu-central-1 \
  --output text \
  --query SecretString \
  > "$SECRET_RAM_DIR/$BACKEND_SECRET"

# setup postgres password file for demo container
if [[ "${TARGET_ENV}" == "demo" ]]; then
  echo "Extracting POSTGRES_PASSWORD for demo instance"
  grep '^POSTGRES_PASSWORD=' "$SECRET_RAM_DIR/$BACKEND_SECRET" \
    | cut -d'=' -f2- \
    > "$SECRET_RAM_DIR/$POSTGRES_SECRET"
  if [[ ! -s "$SECRET_RAM_DIR/$POSTGRES_SECRET" ]]; then
    echo "ERROR: POSTGRES_PASSWORD not found or empty in .env"
    exit 1
  fi
  chmod 400 "$SECRET_RAM_DIR/$POSTGRES_SECRET"

  echo "Querying INITIAL_ADMIN_PASSWORD from AWS Parameter Store"
  INITIAL_ADMIN_PASSWORD=$(aws ssm get-parameter \
    --profile hetzner-pki \
    --region eu-central-1 \
    --name /postgres/user/admin/INITIAL_DEPLOYMENT_PASSWORD \
    --with-decryption \
    --query Parameter.Value \
    --output text)
  if [[ -z "$INITIAL_ADMIN_PASSWORD" ]]; then
    echo "ERROR: Failed to retrieve INITIAL_ADMIN_PASSWORD from Parameter Store"
    exit 1
  fi
  echo "${INITIAL_ADMIN_PASSWORD}" > "$SECRET_RAM_DIR/$ADMIN_SECRET"
fi

# setup webscraper password file for demo container
echo "Extracting JWT_SECRET for demo instance $WEBSCRAPER_SECRET file"
grep '^JWT_SECRET=' "$SECRET_RAM_DIR/$BACKEND_SECRET" \
  > "$SECRET_RAM_DIR/$WEBSCRAPER_SECRET"
if [[ ! -s "$SECRET_RAM_DIR/webscraper.env" ]]; then
  echo "ERROR: JWT_SECRET not found or empty in .env"
  exit 1
fi
echo "Extracting Anthropic API Key from AWS Parameter Store"
ANTHROPIC_KEY=$(aws ssm get-parameter \
  --profile hetzner-pki \
  --region eu-central-1 \
  --name /fastapi/fiscalismia/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text)
if [[ -z "$ANTHROPIC_KEY" ]]; then
  echo "ERROR: Failed to retrieve ANTHROPIC_API_KEY from Parameter Store"
  exit 1
fi
echo "ANTHROPIC_API_KEY=${ANTHROPIC_KEY}" >> "$SECRET_RAM_DIR/$WEBSCRAPER_SECRET"

unset ANTHROPIC_KEY

# read only access to python user id 1001 which runs the uvicorn supervisord service
chmod 400 "$SECRET_RAM_DIR/$WEBSCRAPER_SECRET"
chown 1001:1001 "$SECRET_RAM_DIR/$WEBSCRAPER_SECRET"

# read only access to nodejs user id 1001 which runs the node supervisord service
chmod 400 "$SECRET_RAM_DIR/$BACKEND_SECRET"
chown 1001:1001 "$SECRET_RAM_DIR/$BACKEND_SECRET"
