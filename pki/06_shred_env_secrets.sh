#!/usr/bin/env bash

set -euo pipefail

SECRET_RAM_DIR="/usr/local/etc/fiscalismia-demo/secrets"

if ! mountpoint -q "$SECRET_RAM_DIR" 2>/dev/null; then
  echo "ERROR: ${SECRET_RAM_DIR} is not a mountpoint — refusing to shred"
  exit 1
fi

echo "Shredding $SECRET_RAM_DIR/.env"
shred -vzf -n 5 $SECRET_RAM_DIR/.env
echo "Removing $SECRET_RAM_DIR/.env"
rm -f $SECRET_RAM_DIR/.env
echo "Unmounting $SECRET_RAM_DIR/"
sudo umount $SECRET_RAM_DIR
