#!/usr/bin/env bash

set -euo pipefail

# Automated renewal via systemd timer running as a daemon against a oneshot (executes, then exits) systemd service
# even though the timer runs every x OnUnitActiveSec, step-ca performs a renewal only after 2/3 of the certs validity
RENEW_SERVICE="step-ca-renew-iam-anywhere"
CHECK_INTERVAL="45m"
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
OnBootSec=3min
OnUnitActiveSec=${CHECK_INTERVAL}
RandomizedDelaySec=2min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${RENEW_SERVICE}.timer"
echo "Systemd timer installed and started."

echo "==========================================================================="
echo "  END-ENTITY CERTIFICATE RENEWAL SERVICE SETUP COMPLETE"
echo "==========================================================================="
echo ""
echo "  Renewal:      systemd timer '${RENEW_SERVICE}' (${CHECK_INTERVAL} check interval)"
echo "    Status:     systemctl list-timers | grep ${RENEW_SERVICE}"
echo "    Logs:       journalctl -u ${RENEW_SERVICE}.service"
echo "    Manual run: sudo systemctl start ${RENEW_SERVICE}.service"
echo ""
