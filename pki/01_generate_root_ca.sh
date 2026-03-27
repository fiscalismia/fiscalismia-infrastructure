#!/usr/bin/env bash
# =============================================================================
#
# PURPOSE:
#   Generate an offline Root CA certificate and encrypted private key using
#   step-cli. The root key MUST be kept offline after signing the intermediate.
#
# SECURITY MODEL:
#   - Root CA uses ECDSA P-384 (192-bit security level, future-proof for a
#     long-lived root). We cannot use EdDSA because AWS IAM Roles Anywhere
#     currently (Mar2026) only support RSA and ECDSA ciphersuites
#   - Private key is AES-256 encrypted at rest via step's password prompt.
#   - 5-year validity, preparing for post-quantum security,
#     which requires new algorithms to be used for cert generation
#   - After intermediate signing, the root key goes into cold storage FOREVER.
#
# OUTPUT:
#   $PKI_DIR/root/
#     ├── root_ca.crt          # Root CA certificate (public, distributable)
#     ├── root_ca_key.enc      # Root CA encrypted private key (COLD STORAGE)
#     └── root_ca.fingerprint  # SHA-256 fingerprint for bootstrap verification
#
# =============================================================================
set -euo pipefail

# CONFIGURATION
PKI_BASE="{$HOME}/.pki}"
PKI_DIR="${PKI_BASE}/root"
ROOT_CN="Fiscalismia Root CA"
ROOT_ORG="Fiscalismia"
ROOT_COUNTRY="DE"
ROOT_VALIDITY_YEARS=5
ROOT_KEY_TYPE="EC"
ROOT_KEY_CURVE="P-384"  # 192-bit security; stronger than P-256

# DERIVED
ROOT_CERT="${PKI_DIR}/root_ca.crt"
ROOT_KEY="${PKI_DIR}/root_ca_key.enc"
ROOT_FINGERPRINT_FILE="${PKI_DIR}/root_ca.fingerprint"
ROOT_VALIDITY_HOURS=$(( ROOT_VALIDITY_YEARS * 365 * 24 ))

echo "Running basic validation..."
command -v step >/dev/null 2>&1 || echo "step-cli is not installed. See: https://smallstep.com/docs/step-cli/installation/"
if [[ -f "$ROOT_CERT" ]] || [[ -f "$ROOT_KEY" ]]; then
  echo "Root CA artifacts already exist in ${PKI_DIR}/. To regenerate, manually remove them first."
fi

# Create PKI directory with restrictive permissions
echo "Creating PKI directory: ${PKI_DIR}"
mkdir -p "${PKI_DIR}"
chmod 700 "${PKI_BASE}"
chmod 700 "${PKI_DIR}"

ROOT_PW_FILE=$(mktemp)
# Ensure temp file is cleaned up on exit
trap 'rm -f "${ROOT_PW_FILE}" && exit 1' EXIT SIGKILL SIGINT

# Generate root CA password
echo "You need a STRONG password to encrypt the root CA private key." && echo ""
# Read password twice for confirmation — no echo
while true; do
  read -rsp "  Enter root CA password: " pw1; echo
  read -rsp "  Confirm root CA password: " pw2; echo
  if [[ "$pw1" == "$pw2" ]]; then
    if [[ ${#pw1} -lt 20 ]]; then
      echo "Password is shorter than 20 characters. A longer password is required."
      continue
    fi
    echo -n "$pw1" > "${ROOT_PW_FILE}"
    chmod 600 "${ROOT_PW_FILE}"
    break
  else
    echo "Passwords do not match. Try again."
  fi
done

# Generate Root CA Certificate + Encrypted Key
echo ""
echo "Generating Root CA certificate and key..."
echo "  Subject:   CN=${ROOT_CN}, O=${ROOT_ORG}, C=${ROOT_COUNTRY}"
echo "  Key Type:  ${ROOT_KEY_TYPE} ${ROOT_KEY_CURVE}"
echo "  Validity:  ${ROOT_VALIDITY_YEARS} years (${ROOT_VALIDITY_HOURS}h)"
echo ""

step certificate create \
  "${ROOT_CN}" \
  "${ROOT_CERT}" \
  "${ROOT_KEY}" \
  --profile root-ca \
  --kty "${ROOT_KEY_TYPE}" \
  --crv "${ROOT_KEY_CURVE}" \
  --not-after "${ROOT_VALIDITY_HOURS}h" \
  --password-file "${ROOT_PW_FILE}" \
  --force

# step certificate create with --profile root-ca automatically sets:
#   - Basic Constraints: CA=TRUE, pathlen=1
#   - Key Usage: Certificate Sign, CRL Sign
#   - Subject: CN as provided

echo "Root CA certificate generated: ${ROOT_CERT}"
echo "Root CA encrypted key generated: ${ROOT_KEY}"

# Extract and save SHA-256 fingerprint
FINGERPRINT=$(step certificate fingerprint "${ROOT_CERT}")
echo "${FINGERPRINT}" > "${ROOT_FINGERPRINT_FILE}"
chmod 644 "${ROOT_FINGERPRINT_FILE}"

echo "Root CA SHA-256 fingerprint: ${FINGERPRINT}"
echo "Fingerprint saved to: ${ROOT_FINGERPRINT_FILE}"

# Verify the generated certificate
echo "=========================================="
echo "Verifying generated Root CA certificate..."
echo "=========================================="
step certificate inspect "${ROOT_CERT}" --short
echo ""

# Set restrictive file permissions
chmod 644 "${ROOT_CERT}"         # Public cert
chmod 600 "${ROOT_KEY}"          # Private key
chmod 644 "${ROOT_FINGERPRINT_FILE}"

# Final instructions
echo "==========================================================================="
echo "  ROOT CA GENERATION COMPLETE"
echo "==========================================================================="
echo ""
echo "  Certificate : ${ROOT_CERT}"
echo "  Private Key : ${ROOT_KEY}"
echo "  Fingerprint : ${ROOT_FINGERPRINT_FILE}"
echo ""
echo "  CRITICAL NEXT STEPS:"
echo "     1) DELETE the root key from this workstation:"
echo "        shred -vfz -n 5 ${ROOT_KEY} && rm -f ${ROOT_KEY}"
echo "     2) The root CERTIFICATE (${ROOT_CERT}) and FINGERPRINT"
echo "        should remain accessible — they are public and needed for"
echo "        trust bootstrapping on all nodes."
echo "==========================================================================="