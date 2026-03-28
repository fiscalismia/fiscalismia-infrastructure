#!/usr/bin/env bash

# INFO: RUN REMOTELY ON TARGET MACHINE IN CLOUD
set -euo pipefail

PKI_DIR=/usr/local/etc/fiscalismia-demo/pki

podman run \
    -v step:/home/step:z \
    -p 9000:9000 \
    --rm \
    --detach \
    --name fiscalismia-pki \
    -e "DOCKER_STEPCA_INIT_NAME=Fiscalismia Root CA" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=fiscalismia-pki,localhost,$(hostname -f)" \
    -e "DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT=true" \
    docker.io/smallstep/step-ca:0.30.2

INTERMEDIATE_PW_FILE=$(mktemp)
read -rsp "  Enter root CA password: " pw1; echo
echo -n "$pw1" > "${INTERMEDIATE_PW_FILE}"

podman exec fiscalismia-pki step certificate create end-entity end-entity.crt end-entity.key --profile leaf \
    --ca $PKI_DIR/intermediate-ca.crt --ca-key $PKI_DIR/intermediary-ca-key.enc --ca-password-file $INTERMEDIATE_PW_FILE