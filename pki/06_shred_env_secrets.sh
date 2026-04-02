#!/usr/bin/env bash
set -euo pipefail

SECRET_RAM_DIR="/usr/local/etc/fiscalismia-demo/secrets"
STEP_CA_HOME="/usr/local/etc/step-ca"
SECRET_FILES=(backend.env webscraper.env postgres_password)
STEP_CA_DIRS=(config certs secrets db templates)

if ! mountpoint -q "$SECRET_RAM_DIR" 2>/dev/null; then
  echo "ERROR: ${SECRET_RAM_DIR} is not a mountpoint — refusing to shred"
  exit 1
fi

# Shred and remove each secret file
for secret in "${SECRET_FILES[@]}"; do
  target="$SECRET_RAM_DIR/$secret"
  if [[ -f "$target" ]]; then
    echo "[Shredding] $target"
    shred -vzf -n 3 "$target"
    echo "[Removing] $target"
    rm -f "$target"
  else
    echo "WARN: $target not found, skipping"
  fi
done

# Shred all files inside each step-ca directory
for dir in "${STEP_CA_DIRS[@]}"; do
  target_dir="$STEP_CA_HOME/$dir"
  if [[ -d "$target_dir" ]]; then
    echo "[Shredding] files in $target_dir/"
    # nullglob: if dir is empty, the glob expands to nothing instead of a literal '*'
    shopt -s nullglob
    for file in "$target_dir"/*; do
      if [[ -f "$file" ]]; then
        shred -vzf -n 3 "$file"
        rm -f "$file"
      fi
    done
    echo "[Removed] files in $target_dir/"
    shopt -u nullglob
  else
    echo "WARN: $target_dir/ not found, skipping"
  fi
done

# Unmounting actively mounted podman volume mounts is not wise, shredding and removing the secrets should be sufficient
# echo "Unmounting $SECRET_RAM_DIR/"
# sudo umount "$SECRET_RAM_DIR"