#!/usr/bin/env bash

################################ INFO ###############################################################################################
# This file installs required tools for generating the pki infrastructure and certificates during webservice deployment pipeline runs
# PARAM $1 is the release version of the X86_64/Linux/Amzn2023/aws_signing_helper
# e.g. ./scripts/install-pki-sts-base-requirements.sh 1.8.0
#####################################################################################################################################

AWS_SIGNING_HELPER_VERSION="$1"

if [[ -z "$1" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <AWS_SIGNING_HELPER_VERSION>"
    exit 1
fi

# Install step-ca cli for setting up pki infrastructure
cat <<EOT | sudo tee /etc/yum.repos.d/smallstep.repo > /dev/null
[smallstep]
name=Smallstep
baseurl=https://packages.smallstep.com/stable/fedora/
enabled=1
repo_gpgcheck=0
gpgcheck=1
gpgkey=https://packages.smallstep.com/keys/smallstep-0x889B19391F774443.gpg
EOT
sudo dnf makecache
sudo dnf install -y --quiet jq step-cli

# Download and copy AWS signing helper binary for renewing short-lived STS credentials via credential_process by authenticating with X.509 PKI Certs
cd /tmp
curl -sLO https://rolesanywhere.amazonaws.com/releases/${AWS_SIGNING_HELPER_VERSION}/X86_64/Linux/Amzn2023/aws_signing_helper
mv /tmp/aws_signing_helper /usr/local/bin/aws_signing_helper
sudo chmod 744 /usr/local/bin/aws_signing_helper

echo "##### PKI INSTALLATION #####"
echo "Installed AWS Signing Helper Version:"
/usr/local/bin/aws_signing_helper version
echo "Installed step-ca cli version"
step --version