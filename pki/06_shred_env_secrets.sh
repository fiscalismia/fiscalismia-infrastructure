#!/usr/bin/env bash

SECRET_RAM_DIR="/usr/local/etc/fiscalismia-demo/secrets"
shred -vzf -n 5 $SECRET_RAM_DIR/.env
rm -f $SECRET_RAM_DIR/.env
sudo umount $SECRET_RAM_DIR
