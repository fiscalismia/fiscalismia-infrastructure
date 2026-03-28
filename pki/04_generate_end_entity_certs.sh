#!/usr/bin/env bash

# INFO: RUN VIA WEBSERVICE-DEPLOYMENT PIPELINE ON REMOTE VM
# ./04_generate_end_entity_certs.sh fiscalismia.com backend.fiscalismia.com fastapi.fiscalismia.com
set -euo pipefail

### CONFIGURATION
CA_URL="https://localhost:9000"
CERT_DIR="/etc/step/certs"
ROOT_CA_PATH="/usr/local/etc/step-ca/certs/root-ca.pem"
ACME_PROVISIONER="${ACME_PROVISIONER:-acme}"
RENEW_SERVICE_PREFIX="step-ca-renew"

# Argument parsing
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <domain> [additional-san-domains...]"
  echo ""
  echo "Examples:"
  echo "  $0 backend.fiscalismia.com"
  echo "  $0 fiscalismia.com backend.fiscalismia.com fastapi.fiscalismia.com"
  echo ""
  echo "The first domain is the CN; all domains become SANs."
  exit 1
fi

PRIMARY_DOMAIN="$1"
ALL_DOMAINS=("$@")

# Derive filenames from primary domain
CERT_FILE="${CERT_DIR}/${PRIMARY_DOMAIN}.pem"
KEY_FILE="${CERT_DIR}/${PRIMARY_DOMAIN}.key"

echo "Running basic verification..."
command -v step >/dev/null 2>&1 || echo "step-cli is not installed."
[[ -f "${ROOT_CA_PATH}" ]] || echo "Root CA not found at ${ROOT_CA_PATH}."

# Check step-ca is reachable
echo "Checking step-ca health at ${CA_URL}..."
if step ca health --ca-url "${CA_URL}" --root "${ROOT_CA_PATH}" 2>/dev/null | grep -q "ok"; then
  echo "step-ca is healthy."
else
  echo "Cannot reach step-ca at ${CA_URL}. Is the container running?"
fi

# ---------------------------------------------------------------------------
# Create cert directory
# ---------------------------------------------------------------------------
sudo mkdir -p "${CERT_DIR}"
sudo chmod 755 "${CERT_DIR}"

# ---------------------------------------------------------------------------
# Request certificate via ACME
# ---------------------------------------------------------------------------
echo ""
echo "Requesting TLS certificate for: ${ALL_DOMAINS[*]}"
echo "  Provisioner: ${ACME_PROVISIONER} (ACME)"
echo "  CA URL:      ${CA_URL}"
echo "  Output cert: ${CERT_FILE}"
echo "  Output key:  ${KEY_FILE}"
echo ""

# Build SAN flags for additional domains
SAN_FLAGS=""
for domain in "${ALL_DOMAINS[@]:1}"; do
  SAN_FLAGS="${SAN_FLAGS} --san ${domain}"
done

# step ca certificate with ACME provisioner uses standalone challenge by default.
# For standalone http-01: step-ca connects back to the host on port 80 to verify.
# Since step-ca runs on localhost, this works if port 80 is free momentarily.
#
# If port 80 is occupied (e.g., by nginx), use the --standalone flag or
# configure --webroot to serve the challenge token via the existing web server.
#
# For internal PKI where the CA trusts its own decisions, you can also use
# the JWK admin provisioner instead of ACME for initial issuance, and then
# rely on 'step ca renew' (which uses mTLS, not ACME) for all subsequent
# renewals. This avoids the challenge port problem entirely.

sudo step ca certificate \
  "${PRIMARY_DOMAIN}" \
  "${CERT_FILE}" \
  "${KEY_FILE}" \
  --provisioner "${ACME_PROVISIONER}" \
  --ca-url "${CA_URL}" \
  --root "${ROOT_CA_PATH}" \
  ${SAN_FLAGS} \
  --force

echo "Certificate issued successfully."

# ---------------------------------------------------------------------------
# Set permissions
# ---------------------------------------------------------------------------
sudo chmod 644 "${CERT_FILE}"
sudo chmod 600 "${KEY_FILE}"

# ---------------------------------------------------------------------------
# Inspect the certificate
# ---------------------------------------------------------------------------
echo ""
echo "Certificate details:"
step certificate inspect "${CERT_FILE}" --short
echo ""

# ---------------------------------------------------------------------------
# Setup automated renewal via systemd
# ---------------------------------------------------------------------------
echo ""
read -rp "Install systemd timer for automated renewal? [Y/n]: " setup_renew
if [[ "$setup_renew" =~ ^[Nn]$ ]]; then
  echo ""
  echo "  Manual renewal command:"
  echo "    step ca renew ${CERT_FILE} ${KEY_FILE} \\"
  echo "      --ca-url ${CA_URL} --root ${ROOT_CA_PATH} --force"
  echo ""
  exit 0
fi

# Service name based on domain (sanitize dots for systemd)
SERVICE_NAME="${RENEW_SERVICE_PREFIX}-${PRIMARY_DOMAIN//./-}"

echo "Creating systemd service and timer: ${SERVICE_NAME}"

# The renewal service
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=Renew TLS certificate for ${PRIMARY_DOMAIN} via step-ca
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Renew the certificate. --force overwrites the existing cert+key files.
# --expires-in triggers renewal only when the cert is within 1/3 of its
# lifetime from expiring (step's default behavior).
ExecStart=/usr/bin/step ca renew \\
    ${CERT_FILE} ${KEY_FILE} \\
    --ca-url ${CA_URL} \\
    --root ${ROOT_CA_PATH} \\
    --force

# After successful renewal, reload services that use the cert.
# Uncomment and adapt as needed:
# ExecStartPost=/usr/bin/systemctl reload nginx
# ExecStartPost=/usr/bin/podman exec fiscalismia-backend kill -HUP 1

# Security hardening
ProtectSystem=full
ProtectHome=true
NoNewPrivileges=yes
PrivateTmp=true
EOF

# The renewal timer — check every 8 hours
sudo tee "/etc/systemd/system/${SERVICE_NAME}.timer" > /dev/null <<EOF
[Unit]
Description=Timer for TLS certificate renewal of ${PRIMARY_DOMAIN}

[Timer]
# Run the renewal check periodically.
# step ca renew is idempotent — it only renews when nearing expiry.
OnBootSec=5min
OnUnitActiveSec=8h
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}.timer"

echo "Systemd timer installed and started."

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==========================================================================="
echo "  CERTIFICATE ISSUANCE COMPLETE"
echo "==========================================================================="
echo ""
echo "  Certificate: ${CERT_FILE}"
echo "  Private Key: ${KEY_FILE}"
echo ""
echo "  Renewal:     Automated via systemd timer (every 8h check)"
echo "    Service:   ${SERVICE_NAME}.service"
echo "    Timer:     ${SERVICE_NAME}.timer"
echo ""
echo "  Verify timer status:"
echo "    systemctl list-timers | grep ${SERVICE_NAME}"
echo "    journalctl -u ${SERVICE_NAME}.service"
echo ""
echo "  For nginx/HAProxy, point to these cert files and reload on renewal"
echo "  by uncommenting the ExecStartPost lines in the service file:"
echo "    sudo systemctl edit ${SERVICE_NAME}.service"
echo ""
echo "  To manually test renewal:"
echo "    sudo systemctl start ${SERVICE_NAME}.service"
echo "    journalctl -u ${SERVICE_NAME}.service -n 20"
echo ""
echo "==========================================================================="