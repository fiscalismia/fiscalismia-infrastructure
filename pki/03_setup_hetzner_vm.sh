#!/usr/bin/env bash

# INFO: RUN VIA WEBSERVICE-DEPLOYMENT PIPELINE ON REMOTE VM
set -euo pipefail

### CONFIGURATION ###
STEP_CA_HOME="/usr/local/etc/step-ca"
CA_DNS_NAMES="localhost,fiscalismia-pki,$(hostname -f)"
CA_PORT="9000"
CONTAINER_HOME="/home/step"

# Leaf certificate defaults
DEFAULT_TLS_CERT_DURATION="168h"   # 7 days
MAX_TLS_CERT_DURATION="168h"       # 7 days
MIN_TLS_CERT_DURATION="1h"
JWK_PROVISIONER_NAME="iam-anywhere"

# X.509 subject embedded in the template — MUST match your IAM trust policy:
#   aws:PrincipalTag/x509Subject/CN = "Fiscalismia End Entity"
#   aws:PrincipalTag/x509Subject/O  = "Fiscalismia"
#   aws:PrincipalTag/x509Subject/C  = "DE"
IAM_CERT_ORG="Fiscalismia"
IAM_CERT_COUNTRY="DE"

# Container UID/GID (smallstep/step-ca runs as user 'step' UID 1000)
STEP_UID=1000
STEP_GID=1000


echo "Verifiying program installations..."
command -v step >/dev/null 2>&1 || { echo "step-cli is not installed."; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "jq is not installed.";       exit 1; }

# Create directory structure
echo "Creating directory structure at ${STEP_CA_HOME}..."
sudo mkdir -p "${STEP_CA_HOME}"/{config,certs,secrets,db,templates}
sudo chown -R "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}"
sudo chmod 700 "${STEP_CA_HOME}/secrets"
sudo chmod 700 "${STEP_CA_HOME}/db"

# Place PKI files manually (REPLACE WITH SCP IN PIPELINE)
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

# Intermediate key password (REPLACE WITH SECRETS_MGR IN PIPELINE)
read -rsp "  Intermediate CA password: " int_pw; echo
sudo bash -c "echo -n '${int_pw}' > '${STEP_CA_HOME}/secrets/password'"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/secrets/password"
sudo chmod 600 "${STEP_CA_HOME}/secrets/password"
echo "Password file written."

# ---------------------------------------------------------------------------
# Generate JWK provisioner key pair
# ---------------------------------------------------------------------------
# The JWK provisioner authenticates cert requests via signed JWTs.
# The key pair and password are generated here at setup time and persisted
echo ""
echo "Generating JWK provisioner key pair for '${JWK_PROVISIONER_NAME}'..."

JWK_PUB_TMP=$(mktemp)
JWK_PRIV_TMP=$(mktemp)
JWK_PW_TMP=$(mktemp)
trap 'rm -f "${JWK_PUB_TMP}" "${JWK_PRIV_TMP}" "${JWK_PW_TMP}"' EXIT

# Generate a strong random provisioner password
head -c 32 /dev/urandom | base64 -w 0 > "${JWK_PW_TMP}"
chmod 600 "${JWK_PW_TMP}"

step crypto jwk create "${JWK_PUB_TMP}" "${JWK_PRIV_TMP}" \
  --kty EC --crv P-256 --use sig \
  --password-file "${JWK_PW_TMP}" \
  --force

# Read generated keys for embedding in ca.json
JWK_PUB_JSON=$(cat "${JWK_PUB_TMP}")
JWK_ENC_KEY=$(cat "${JWK_PRIV_TMP}")

# Persist provisioner password for step ca certificate calls in script 04
sudo cp "${JWK_PW_TMP}" "${STEP_CA_HOME}/secrets/provisioner-password"
sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/secrets/provisioner-password"
sudo chmod 600 "${STEP_CA_HOME}/secrets/provisioner-password"
echo "Provisioner password saved to ${STEP_CA_HOME}/secrets/provisioner-password"

# Write X.509 template for IAM Roles Anywhere end-entity certs
echo "Writing X.509 template for IAM end-entity certs..."
TEMPLATE_FILENAME="iam-anywhere-leaf.tpl"
TEMPLATE_HOST_PATH="${STEP_CA_HOME}/templates/${TEMPLATE_FILENAME}"
TEMPLATE_CONTAINER_PATH="${CONTAINER_HOME}/templates/${TEMPLATE_FILENAME}"

sudo tee "${TEMPLATE_HOST_PATH}" > /dev/null <<'TEMPLATE'
{
  "subject": {
    "commonName": {{ toJson .Subject.CommonName }},
    "organization": "Fiscalismia",
    "country": "DE"
  },
  "keyUsage": ["digitalSignature"],
  "extKeyUsage": ["clientAuth"],
  "basicConstraints": {
    "isCA": false
  }
}
TEMPLATE

sudo chown "${STEP_UID}:${STEP_GID}" "${TEMPLATE_HOST_PATH}"
sudo chmod 644 "${TEMPLATE_HOST_PATH}"
echo "Template written to ${TEMPLATE_HOST_PATH}"

echo "Generating ca.json..."
# Convert comma-separated DNS names to JSON array
IFS=',' read -ra DNS_ARRAY <<< "${CA_DNS_NAMES}"
DNS_JSON=$(printf '%s\n' "${DNS_ARRAY[@]}" | jq -R . | jq -s .)

# Build ca.json with jq for correct JSON
jq -n \
  --arg root "${CONTAINER_HOME}/certs/root-ca.pem" \
  --arg crt "${CONTAINER_HOME}/certs/intermediate-ca.pem" \
  --arg key "${CONTAINER_HOME}/secrets/intermediate-ca-key.enc" \
  --arg port ":${CA_PORT}" \
  --argjson dns "${DNS_JSON}" \
  --arg min_dur "${MIN_TLS_CERT_DURATION}" \
  --arg max_dur "${MAX_TLS_CERT_DURATION}" \
  --arg def_dur "${DEFAULT_TLS_CERT_DURATION}" \
  --arg db "${CONTAINER_HOME}/db" \
  --arg jwk_name "${JWK_PROVISIONER_NAME}" \
  --argjson jwk_pub "${JWK_PUB_JSON}" \
  --arg jwk_enc "${JWK_ENC_KEY}" \
  --arg tpl_path "${TEMPLATE_CONTAINER_PATH}" \
  '{
    root: $root,
    crt: $crt,
    key: $key,
    address: $port,
    insecureAddress: "",
    dnsNames: $dns,
    logger: { format: "json" },
    db: {
      type: "badgerv2",
      dataSource: $db
    },
    authority: {
      claims: {
        minTLSCertDuration: $min_dur,
        maxTLSCertDuration: $max_dur,
        defaultTLSCertDuration: $def_dur,
        disableRenewal: false,
        allowRenewalAfterExpiry: false
      },
      provisioners: [
        {
          type: "JWK",
          name: $jwk_name,
          key: $jwk_pub,
          encryptedKey: $jwk_enc,
          claims: {
            maxTLSCertDuration: $max_dur,
            defaultTLSCertDuration: $def_dur
          },
          options: {
            x509: {
              templateFile: $tpl_path
            }
          }
        }
      ]
    },
    tls: {
      cipherSuites: [
        "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
      ],
      minVersion: 1.2,
      maxVersion: 1.3,
      renegotiation: false
    }
  }' | sudo tee "${STEP_CA_HOME}/config/ca.json" > /dev/null

sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/config/ca.json"
sudo chmod 644 "${STEP_CA_HOME}/config/ca.json"
echo "ca.json generated."

# Generate defaults.json (used by step-cli on the host)
echo "Generating defaults.json..."
FIRST_DNS=$(echo "${CA_DNS_NAMES}" | cut -d',' -f1)
FINGERPRINT=$(cat "${STEP_CA_HOME}/certs/root-ca.fingerprint" 2>/dev/null || echo "Unknown")

jq -n \
  --arg url "https://${FIRST_DNS}:${CA_PORT}" \
  --arg config "${CONTAINER_HOME}/config/ca.json" \
  --arg fp "${FINGERPRINT}" \
  --arg root "${CONTAINER_HOME}/certs/root-ca.pem" \
  '{
    "ca-url": $url,
    "ca-config": $config,
    fingerprint: $fp,
    root: $root
  }' | sudo tee "${STEP_CA_HOME}/config/defaults.json" > /dev/null

sudo chown "${STEP_UID}:${STEP_GID}" "${STEP_CA_HOME}/config/defaults.json"
sudo chmod 644 "${STEP_CA_HOME}/config/defaults.json"
echo "defaults.json generated."

# Bootstrap step-cli on the host to trust this CA
if command -v step >/dev/null 2>&1; then
  echo "Bootstrapping step-cli on the host to trust this CA..."
  step ca bootstrap \
    --ca-url "https://${FIRST_DNS}:${CA_PORT}" \
    --fingerprint "${FINGERPRINT}" \
    --install 2>/dev/null || echo "Bootstrap will succeed once step-ca is running."
fi

# Summary
echo ""
echo "==========================================================================="
echo ""
echo "  step-ca home:       ${STEP_CA_HOME}"
echo "  CA URL:             https://${FIRST_DNS}:${CA_PORT}"
echo "  Fingerprint:        ${FINGERPRINT}"
echo ""
echo "  Provisioners:"
echo "    JWK '${JWK_PROVISIONER_NAME}' — for IAM Roles Anywhere end-entity certs"
echo "      Template:       ${TEMPLATE_HOST_PATH}"
echo "      Password file:  ${STEP_CA_HOME}/secrets/provisioner-password"
echo ""
echo "  Host volume layout (mounted as ${CONTAINER_HOME}):"
echo "    ${STEP_CA_HOME}/"
echo "    ├── config/"
echo "    │   ├── ca.json"
echo "    │   └── defaults.json"
echo "    ├── certs/"
echo "    │   ├── root-ca.pem"
echo "    │   ├── root-ca.fingerprint"
echo "    │   └── intermediate-ca.pem"
echo "    ├── secrets/"
echo "    │   ├── intermediate-ca-key.enc"
echo "    │   ├── password"
echo "    │   └── provisioner-password"
echo "    ├── db/"
echo "    └── templates/"
echo "        └── ${TEMPLATE_FILENAME}"
echo ""
echo "  NEXT: Start the CA with:"
echo "    cd /usr/local/etc/fiscalismia-demo && docker compose up --no-deps fiscalismia-pki -d"
echo ""
echo "  THEN: Generate end-entity cert with:"
echo "    ./04_generate_end_entity_certs.sh"
echo ""
echo "==========================================================================="