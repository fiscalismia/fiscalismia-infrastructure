#!/usr/bin/env bash

set -euo pipefail

SECRET_RAM_DIR="/usr/local/etc/fiscalismia-demo/secrets"
BACKEND_SECRET="backend.env"
WEBSCRAPER_SECRET="webscraper.env"
POSTGRES_SECRET="postgres_password"

if ! mountpoint -q "$SECRET_RAM_DIR" 2>/dev/null; then
  echo "ERROR: ${SECRET_RAM_DIR} is not a mountpoint — refusing to shred"
  exit 1
fi

echo "Shredding $SECRET_RAM_DIR/$BACKEND_SECRET"
shred -vzf -n 3 $SECRET_RAM_DIR/$BACKEND_SECRET
echo "Removing $SECRET_RAM_DIR/$BACKEND_SECRET"
rm -f $SECRET_RAM_DIR/$BACKEND_SECRET

echo "Unmounting $SECRET_RAM_DIR/"
sudo umount $SECRET_RAM_DIR
