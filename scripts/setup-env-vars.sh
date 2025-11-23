#!/usr/bin/env bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

read -p "Please provide your AWS_ACCESS_KEY_ID: " ACCESS_KEY
read -p "Please provide your AWS_SECRET_ACCESS_KEY: " SECRET_KEY
read -p "Please provide your HCLOUD_TOKEN: " HCLOUD_TOKEN

AWS_REGION="eu-central-1"

cd ..
# create terraform .env file for hcloud and aws
touch terraform/.env
echo "# AWS CONFIG
export AWS_ACCESS_KEY_ID="${ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${SECRET_KEY}"
export AWS_REGION="${AWS_REGION}"
export HCLOUD_TOKEN="${HCLOUD_TOKEN}"
# TF VARS
export TF_VAR_EXAMPLE_VAR="example-env-var"
" > terraform/.env
echo "--------------------------------"
echo "Created .env file with terraform secrets in"
echo "$(pwd)/terraform/.env"
echo "--------------------------------"
