#!/usr/bin/env bash
# =============================================================================
# Generate an Intermediate CA certificate signed by the Root CA. This
# intermediate will be deployed to a Hetzner VM running step-ca in an OCI
# container to issue end-entity (leaf) TLS certificates on demand.
#
# SECURITY MODEL:
#   - Intermediate uses ECDSA P-384 (192-bit security level, future-proof for a
#     long-lived root). We cannot use EdDSA because AWS IAM Roles Anywhere
#     currently (Mar2026) only support RSA and ECDSA ciphersuites
#   - 5-year validity, preparing for post-quantum security,
#     which requires new algorithms to be used for cert generation
#   - Separate password from the root CA key (defense in depth).
#   - pathLen=0 constrains this intermediate from creating further sub-CAs.
#   - The intermediate key will be the ONLY signing key on the Hetzner VM.
#     The root key is NEVER transferred to any server.
#
# PREREQUISITES:
#   - 01_generate_root_ca.sh must have been run successfully
#   - Root CA cert and encrypted key must still be available locally
#
# OUTPUT:
#   $PKI_DIR/intermediate/
#     ├── intermediate-ca.pem        # Intermediate CA cert
#     └── intermediate-ca-key.env    # Intermediate CA encrypted key
#
# =============================================================================
set -euo pipefail

#### CONFIGURATION ####
PKI_BASE="${HOME}/.pki"
ROOT_DIR="${PKI_BASE}/root"
INTERMEDIATE_DIR="${PKI_BASE}/intermediate"

ROOT_CERT="${ROOT_DIR}/root-ca.pem"
ROOT_KEY="${ROOT_DIR}/root-ca-key.enc"

INTERMEDIATE_CN="Fiscalismia Intermediate CA 01"
INTERMEDIATE_ORG="Fiscalismia" # should be the same across the chain
INTERMEDIATE_COUNTRY="DE"      # should be the same across the chain
INTERMEDIATE_VALIDITY_YEARS=5
INTERMEDIATE_KEY_TYPE="EC"
INTERMEDIATE_KEY_CURVE="P-384"  # 192-bit security; stronger than P-256

INTERMEDIATE_CERT="${INTERMEDIATE_DIR}/intermediate-ca.pem"
INTERMEDIATE_KEY="${INTERMEDIATE_DIR}/intermediate-ca-key.enc"
INTERMEDIATE_VALIDITY_HOURS=$(( INTERMEDIATE_VALIDITY_YEARS * 365 * 24 ))

# Running verification of root-ca generation
echo "Running verification of root-ca generation"

# check for local step installation
command -v step >/dev/null 2>&1 || echo "step-cli is not installed."
# check root certificate and keys
[[ -f "$ROOT_CERT" ]] || echo "Root CA certificate not found at: ${ROOT_CERT}. Run 01_generate_root_ca.sh first."
[[ -f "$ROOT_KEY" ]]  || echo "Root CA key not found at: ${ROOT_KEY}."
# check for pre-existing intermediary cert
if [[ -f "$INTERMEDIATE_CERT" ]] || [[ -f "$INTERMEDIATE_KEY" ]]; then
  echo "Intermediate CA artifacts already exist in ${INTERMEDIATE_DIR}/. Remove them manually to regenerate."
fi
# Verify root cert is actually a CA certificate
if ! step certificate inspect "${ROOT_CERT}" --format json 2>/dev/null | grep -q '"is_ca": true'; then
  # Fallback: check with the short format
  if ! step certificate inspect "${ROOT_CERT}" --short 2>/dev/null | grep -qi "CA:TRUE"; then
    echo "Root certificate at ${ROOT_CERT} does not appear to be a CA certificate."
  fi
fi
# Verify root cert is not expired
if ! step certificate verify "${ROOT_CERT}" --roots="${ROOT_CERT}" 2>/dev/null; then
  echo "Root CA certificate is expired or invalid."
fi

# Create intermediate directory
echo "Creating intermediate directory: ${INTERMEDIATE_DIR}"
mkdir -p "${INTERMEDIATE_DIR}"
chmod 700 "${INTERMEDIATE_DIR}"

# Collect passwords
ROOT_PW_FILE=$(mktemp)
INTERMEDIATE_PW_FILE=$(mktemp)
# Ensure temp files are cleaned up on exit
trap 'rm -f "${ROOT_PW_FILE}" "${INTERMEDIATE_PW_FILE}"' EXIT
trap 'exit 1' SIGINT SIGTERM

read -rsp "  Enter ROOT CA password (to sign the intermediate): " root_pw; echo
echo -n "$root_pw" > "${ROOT_PW_FILE}"
chmod 600 "${ROOT_PW_FILE}"

# Read password twice for confirmation
while true; do
  read -rsp "  Enter intermediate CA password: " pw1; echo
  read -rsp "  Confirm intermediate CA password: " pw2; echo
  if [[ "$pw1" == "$pw2" ]]; then
    if [[ "$pw1" == "$root_pw" ]]; then
      echo "Intermediate password MUST be different from the root password (defense in depth)."
      continue
    fi
    if [[ ${#pw1} -lt 20 ]]; then
      echo "Password is shorter than 20 characters. A longer password is required."
      continue
    fi
    echo -n "$pw1" > "${INTERMEDIATE_PW_FILE}"
    chmod 600 "${INTERMEDIATE_PW_FILE}"
    break
  else
    echo "Passwords do not match. Try again."
  fi
done

# Generate Intermediate CA Certificate signed by Root
echo ""
echo "Generating Intermediate CA certificate..."
echo "  Subject:    CN=${INTERMEDIATE_CN}, O=${INTERMEDIATE_ORG}"
echo "  Signed by:  ${ROOT_CERT}"
echo "  Key Type:   ${INTERMEDIATE_KEY_TYPE} ${INTERMEDIATE_KEY_CURVE}"
echo "  Validity:   ${INTERMEDIATE_VALIDITY_YEARS} years (${INTERMEDIATE_VALIDITY_HOURS}h)"
echo ""

# Write intermediate CA certificate template with full X.500 subject
INTERMEDIATE_TEMPLATE="${INTERMEDIATE_DIR}/intermediate-ca.tpl"
cat > "${INTERMEDIATE_TEMPLATE}" <<EOF
{
  "subject": {
    "commonName": "{{ .Subject.CommonName }}",
    "organization": "${INTERMEDIATE_ORG}",
    "country": "${INTERMEDIATE_COUNTRY}"
  },
  "keyUsage": ["certSign", "crlSign"],
  "basicConstraints": {
    "isCA": true,
    "maxPathLen": 0
  }
}
EOF
chmod 600 "${INTERMEDIATE_TEMPLATE}"

step certificate create \
  "${INTERMEDIATE_CN}" \
  "${INTERMEDIATE_CERT}" \
  "${INTERMEDIATE_KEY}" \
  --template "${INTERMEDIATE_TEMPLATE}" \
  --ca "${ROOT_CERT}" \
  --ca-key "${ROOT_KEY}" \
  --ca-password-file "${ROOT_PW_FILE}" \
  --password-file "${INTERMEDIATE_PW_FILE}" \
  --kty "${INTERMEDIATE_KEY_TYPE}" \
  --crv "${INTERMEDIATE_KEY_CURVE}" \
  --not-after "${INTERMEDIATE_VALIDITY_HOURS}h" \
  --force

echo "Intermediate CA certificate generated: ${INTERMEDIATE_CERT}"
echo "Intermediate CA encrypted key generated: ${INTERMEDIATE_KEY}"

# Verify the chain
echo "Verifying certificate chain (Intermediate -> Root)..."
if step certificate verify "${INTERMEDIATE_CERT}" --roots="${ROOT_CERT}" 2>/dev/null; then
  echo "Certificate chain verification PASSED."
else
  echo "Certificate chain verification echoED. The intermediate is not properly signed by the root."
fi

# Verify the generated certificate visually
echo "==================================================="
echo "Inspecting generated Intermediary CA certificate..."
echo "==================================================="
step certificate inspect "${INTERMEDIATE_CERT}" --short
echo ""

# Set restrictive file permissions
chmod 644 "${INTERMEDIATE_CERT}"   # Public cert
chmod 600 "${INTERMEDIATE_KEY}"    # Private key

# Generate bundle (root + intermediate public certs)
BUNDLE_FILE="${INTERMEDIATE_DIR}/ca-bundle.pem"
cat "${INTERMEDIATE_CERT}" "${ROOT_CERT}" > "${BUNDLE_FILE}"
chmod 644 "${BUNDLE_FILE}"
echo "CA bundle (intermediate + root) written to: ${BUNDLE_FILE}"

# Final summary of script execution and further instructions
FINGERPRINT=$(step certificate fingerprint "${ROOT_CERT}")
echo "==========================================================================="
echo "  INTERMEDIATE CA GENERATION COMPLETE"
echo "==========================================================================="
echo "  Intermediate Cert : ${INTERMEDIATE_CERT}"
echo "  Intermediate Key  : ${INTERMEDIATE_KEY}"
echo "  CA Bundle         : ${BUNDLE_FILE}"
echo "  Root Cert         : ${ROOT_CERT}"
echo ""
echo "  FILES TO DEPLOY TO HETZNER VM (step-ca container):"
echo "    - ${ROOT_CERT}"
echo "    - ${INTERMEDIATE_CERT}"
echo "    - ${INTERMEDIATE_KEY}"
echo ""
echo "  CRITICAL NEXT STEPS:"
echo "     0) MOVE the root key to a secure location"
echo "     1) Store both passwords in your password manager"
echo "     2) DELETE the root key from this workstation:"
echo "        shred -vfz -n 5 ${ROOT_KEY}"
echo "        rm -f ${ROOT_KEY}"
echo "     3) The root CERTIFICATE (${ROOT_CERT}) and fingerprint:"
echo "        \"${FINGERPRINT}\""
echo "        should remain accessible for later verification"
echo "==========================================================================="