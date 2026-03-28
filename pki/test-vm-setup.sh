#!/usr/bin/env bash
# =============================================================================
# 04_setup_step_ca_vm.sh — Prepare Hetzner VM for step-ca container deployment
# =============================================================================
#
# PURPOSE:
#   Run this script on the Hetzner VM BEFORE starting docker compose. It creates
#   the directory structure, places the PKI files you SCP'd from your workstation,
#   generates the ca.json config, and sets proper ownership for the container's
#   non-root 'step' user (UID 1000, GID 1000 in the smallstep/step-ca image).
#
# PREREQUISITES:
#   - SCP the following files from your workstation to the VM:
#       scp ~/.fiscalismia-pki/root/root-ca.pem           <vm>:/tmp/pki/
#       scp ~/.fiscalismia-pki/intermediate/intermediate-ca.pem  <vm>:/tmp/pki/
#       scp ~/.fiscalismia-pki/intermediate/intermediate-ca-key.enc  <vm>:/tmp/pki/
#   - Docker/Podman and docker-compose installed on the VM
#   - step-cli installed on the VM host (for ACME cert requests later)
# =============================================================================
set -euo pipefail

### CONFIGURATION
STEP_CA_HOME="/usr/local/etc/step-ca"
CA_DNS_NAMES="localhost,fiscalismia-pki,$(hostname -f)"
CA_PORT="9000"
ACME_ALLOWED_DOMAIN="fiscalismia.com"

# Leaf certificate defaults
DEFAULT_TLS_CERT_DURATION="168h"   # 7 days
MAX_TLS_CERT_DURATION="168h"       # 7 days
MIN_TLS_CERT_DURATION="1h"

# The smallstep/step-ca image runs as UID 1000:GID 1000 (user 'step').
STEP_UID=1000
STEP_GID=1000

# We mirror the container's /home/step layout on the host for bind mounts.
echo "Creating directory structure at ${STEP_CA_HOME}..."
sudo mkdir -p "${STEP_CA_HOME}"/{config,certs,secrets,db,templates}
sudo chown -R "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}"
sudo chmod 700 "${STEP_CA_HOME}/secrets"
sudo chmod 700 "${STEP_CA_HOME}/db"

# ---------------------------------------------------------------------------
# Place PKI files
# ---------------------------------------------------------------------------
read -p """Place PKI files in the following locations:
${STEP_CA_HOME}/certs/root-ca.pem
${STEP_CA_HOME}/certs/root-ca.fingerprint
${STEP_CA_HOME}/certs/intermediate-ca.pem
${STEP_CA_HOME}/secrets/intermediate-ca-key.enc
[Press Enter to continue]
"""
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/certs/root-ca.pem"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/certs/root-ca.fingerprint"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/certs/intermediate-ca.pem"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/secrets/intermediate-ca-key.enc"
sudo chmod 644 "${STEP_CA_HOME}/certs/root-ca.pem"
sudo chmod 644 "${STEP_CA_HOME}/certs/root-ca.fingerprint"
sudo chmod 644 "${STEP_CA_HOME}/certs/intermediate-ca.pem"
sudo chmod 600 "${STEP_CA_HOME}/secrets/intermediate-ca-key.enc"

echo "PKI files placed and permissions set."

# ---------------------------------------------------------------------------
# Intermediate key password
# ---------------------------------------------------------------------------
echo ""
echo "==========================================================================="
echo "  INTERMEDIATE CA KEY PASSWORD"
echo "==========================================================================="
echo ""
echo "  Enter the password you used to encrypt the intermediate CA private key."
echo "  This is stored in ${STEP_CA_HOME}/secrets/password and read by step-ca"
echo "  at startup via --password-file. It is NEVER stored in ca.json."
echo ""

read -rsp "  Intermediate CA password: " int_pw; echo
sudo bash -c "echo -n '${int_pw}' > '${STEP_CA_HOME}/secrets/password'"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/secrets/password"
sudo chmod 600 "${STEP_CA_HOME}/secrets/password"
echo "Password file written."

# ---------------------------------------------------------------------------
# Generate ca.json
# ---------------------------------------------------------------------------
echo "Generating ca.json..."

# Convert comma-separated DNS names to JSON array
IFS=',' read -ra DNS_ARRAY <<< "${CA_DNS_NAMES}"
DNS_JSON=$(printf '%s\n' "${DNS_ARRAY[@]}" | jq -R . | jq -s .)

sudo tee "${STEP_CA_HOME}/config/ca.json" > /dev/null <<CAJSON
{
  "root": "/home/step/certs/root-ca.pem",
  "crt": "/home/step/certs/intermediate-ca.pem",
  "key": "/home/step/secrets/intermediate-ca-key.enc",
  "address": ":${CA_PORT}",
  "insecureAddress": "",
  "dnsNames": ${DNS_JSON},
  "logger": {
    "format": "json"
  },
  "db": {
    "type": "badgerv2",
    "dataSource": "/home/step/db"
  },
  "authority": {
    "claims": {
      "minTLSCertDuration": "${MIN_TLS_CERT_DURATION}",
      "maxTLSCertDuration": "${MAX_TLS_CERT_DURATION}",
      "defaultTLSCertDuration": "${DEFAULT_TLS_CERT_DURATION}",
      "disableRenewal": false,
      "allowRenewalAfterExpiry": false
    },
    "policy": {
      "x509": {
        "allow": {
          "dns": ["*.${ACME_ALLOWED_DOMAIN}", "${ACME_ALLOWED_DOMAIN}"]
        },
        "allowWildcardNames": false
      }
    },
    "provisioners": [
      {
        "type": "ACME",
        "name": "acme",
        "claims": {
          "maxTLSCertDuration": "${MAX_TLS_CERT_DURATION}",
          "defaultTLSCertDuration": "${DEFAULT_TLS_CERT_DURATION}"
        },
        "options": {
          "x509": {}
        }
      }
    ]
  },
  "tls": {
    "cipherSuites": [
      "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
    ],
    "minVersion": 1.2,
    "maxVersion": 1.3,
    "renegotiation": false
  }
}
CAJSON

sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/config/ca.json"
sudo chmod 644 "${STEP_CA_HOME}/config/ca.json"
echo "ca.json generated."

# Generate defaults.json (used by step-cli on the host)
echo "Generating defaults.json..."

# Use first DNS name for the CA URL
FIRST_DNS=$(echo "${CA_DNS_NAMES}" | cut -d',' -f1)
FINGERPRINT=$(cat "${STEP_CA_HOME}/certs/root-ca.fingerprint" || echo "Unknown")

sudo tee "${STEP_CA_HOME}/config/defaults.json" > /dev/null <<DEFAULTS
{
  "ca-url": "https://${FIRST_DNS}:${CA_PORT}",
  "ca-config": "/home/step/config/ca.json",
  "fingerprint": "${FINGERPRINT}",
  "root": "/home/step/certs/root-ca.pem"
}
DEFAULTS

sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/config/defaults.json"
sudo chmod 644 "${STEP_CA_HOME}/config/defaults.json"
echo "defaults.json generated."

# ---------------------------------------------------------------------------
# Bootstrap step-cli on the host to trust this CA
# ---------------------------------------------------------------------------
if command -v step >/dev/null 2>&1; then
  echo "Bootstrapping step-cli on the host to trust this CA..."
  step ca bootstrap \
    --ca-url "https://${FIRST_DNS}:${CA_PORT}" \
    --fingerprint "${FINGERPRINT}" \
    --install 2>/dev/null || echo "Bootstrap will succeed once step-ca is running."
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==========================================================================="
echo "  VM SETUP COMPLETE"
echo "==========================================================================="
echo ""
echo "  step-ca home:  ${STEP_CA_HOME}"
echo "  CA URL:        https://${FIRST_DNS}:${CA_PORT}"
echo "  Fingerprint:   ${FINGERPRINT}"
echo ""
echo "  Directory layout:"
echo "    ${STEP_CA_HOME}/"
echo "    ├── config/"
echo "    │   ├── ca.json          # CA configuration"
echo "    │   └── defaults.json    # Client defaults"
echo "    ├── certs/"
echo "    │   ├── root-ca.pem      # Root CA certificate"
echo "    │   └── intermediate-ca.pem  # Intermediate CA certificate"
echo "    ├── secrets/"
echo "    │   ├── intermediate-ca-key.enc  # Encrypted intermediate key"
echo "    │   └── password             # Key decryption password"
echo "    ├── db/                   # Badger database (persistent)"
echo "    └── templates/            # Certificate templates (future)"
echo ""
echo "  NEXT: Start the CA with:"
echo "    cd /path/to/step-ca-compose && docker compose up -d"
echo ""
echo "==========================================================================="