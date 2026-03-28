#!/usr/bin/env bash

# INFO: RUN VIA WEBSERVICE-DEPLOYMENT PIPELINE ON REMOTE VM

# Generate an end-entity leaf certificate for AWS IAM Roles Anywhere.
# This cert authenticates Hetzner workloads against AWS to receive temporary
# STS credentials via the CreateSession API. It is NOT a TLS server cert.
set -euo pipefail

### CONFIGURATION ###
CA_URL="https://localhost:9000"
STEP_CA_HOME="/usr/local/etc/step-ca"
ROOT_CA_PATH="${STEP_CA_HOME}/certs/root-ca.pem"
PROVISIONER_NAME="iam-anywhere"
PROVISIONER_PW_FILE="${STEP_CA_HOME}/secrets/provisioner-password"

# End-entity cert output (separate from CA files)
CERT_DIR="/etc/pki/iam-anywhere"
CERT_FILE="${CERT_DIR}/end-entity.pem"
KEY_FILE="${CERT_DIR}/end-entity-key.pem"
LEAF_CERT_VALIDITY="168h"

# X.509 subject CN — O and C are enforced server-side by the template
CERT_CN="Fiscalismia End Entity"

# Systemd renewal service
RENEW_SERVICE="step-ca-renew-iam-anywhere"

echo "Verifiying program installations..."
command -v step >/dev/null 2>&1 || { echo "step-cli is not installed."; exit 1; }
[[ -f "${ROOT_CA_PATH}" ]]       || { echo "Root CA not found at ${ROOT_CA_PATH}."; exit 1; }
[[ -f "${PROVISIONER_PW_FILE}" ]] || { echo "Provisioner password not found at ${PROVISIONER_PW_FILE}. Run 03_setup_hetzner_vm.sh first."; exit 1; }

echo "Checking step-ca health at ${CA_URL}..."
if step ca health --ca-url "${CA_URL}" --root "${ROOT_CA_PATH}" 2>/dev/null | grep -q "ok"; then
  echo "step-ca is healthy."
else
  echo "Cannot reach step-ca at ${CA_URL}. Is the container running?"
  exit 1
fi

# Issue end-entity certificate
echo ""
echo "  Issuing end-entity certificate for IAM Roles Anywhere"
echo ""
echo "  Subject:      CN=${CERT_CN} (O and C enforced by server-side template)"
echo "  Key Type:     ECDSA P-256"
echo "  Provisioner:  ${PROVISIONER_NAME} (JWK)"
echo "  Output:       ${CERT_FILE}"
echo ""

sudo mkdir -p "${CERT_DIR}"
sudo chmod 755 "${CERT_DIR}"

# Request the cert. The CN argument populates {{ .Subject.CommonName }} in the template
sudo step ca certificate \
  "${CERT_CN}" \
  "${CERT_FILE}" \
  "${KEY_FILE}" \
  --provisioner "${PROVISIONER_NAME}" \
  --provisioner-password-file "${PROVISIONER_PW_FILE}" \
  --ca-url "${CA_URL}" \
  --root "${ROOT_CA_PATH}" \
  --kty EC --crv P-256 \
  --not-after "${LEAF_CERT_VALIDITY}" \
  --force

echo "End-entity certificate issued."
sudo chmod 644 "${CERT_FILE}"
sudo chmod 600 "${KEY_FILE}"

# Verify certificate visually and against root-ca.pem
echo ""
echo "Inspecting generated End-Entity certificate"
step certificate inspect "${CERT_FILE}" --short

echo "=============================================="
echo "Verifying certificate chain (End-Entity -> Intermediate -> Root)..."
if step certificate verify "${CERT_FILE}" --roots "${ROOT_CA_PATH}" 2>/dev/null; then
  echo "Chain verification PASSED."
else
  echo "Chain verification FAILED."
  exit 1
fi

# Automated renewal via systemd timer running as a daemon against a oneshot (executes, then exits) systemd service
# even though the timer runs every x OnUnitActiveSec, step-ca performs a renewal only after 2/3 of the certs validity
echo "  Setting up automated certificate renewal"
sudo tee "/etc/systemd/system/${RENEW_SERVICE}.service" > /dev/null <<EOF
[Unit]
Description=Renew IAM Roles Anywhere end-entity certificate via step-ca
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/step ca renew \\
    ${CERT_FILE} ${KEY_FILE} \\
    --ca-url ${CA_URL} \\
    --root ${ROOT_CA_PATH} \\
    --force

ProtectSystem=full
ProtectHome=true
NoNewPrivileges=yes
PrivateTmp=true
EOF

sudo tee "/etc/systemd/system/${RENEW_SERVICE}.timer" > /dev/null <<EOF
[Unit]
Description=Timer for IAM Roles Anywhere certificate renewal

[Timer]
OnBootSec=5min
OnUnitActiveSec=8h
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${RENEW_SERVICE}.timer"
echo "Systemd timer installed and started."

# Final summary of script execution and further instructions
echo "==========================================================================="
echo "  END-ENTITY CERTIFICATE ISSUANCE COMPLETE"
echo "==========================================================================="
echo ""
echo "  Certificate:  ${CERT_FILE}"
echo "  Private Key:  ${KEY_FILE}"
echo ""
echo "  Subject:      CN=${CERT_CN}, O=Fiscalismia, C=DE"
echo "  Key Type:     ECDSA P-256"
echo "  Validity:     7 days (renewed automatically)"
echo ""
echo "  Renewal:      systemd timer '${RENEW_SERVICE}' (8h check interval)"
echo "    Status:     systemctl list-timers | grep ${RENEW_SERVICE}"
echo "    Logs:       journalctl -u ${RENEW_SERVICE}.service"
echo "    Manual run: sudo systemctl start ${RENEW_SERVICE}.service"
echo ""
echo "  AWS Roles Anywhere usage:"
echo "    aws_signing_helper credential-process \\"
echo "      --certificate ${CERT_FILE} \\"
echo "      --private-key ${KEY_FILE} \\"
echo "      --trust-anchor-arn <TRUST_ANCHOR_ARN> \\"
echo "      --profile-arn <PROFILE_ARN> \\"
echo "      --role-arn <ROLE_ARN>"
echo ""
echo "==========================================================================="