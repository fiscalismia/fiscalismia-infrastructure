#!/bin/bash

##############################################################
# Call Script with API_ENDPOINT Selection String at Position 1
##############################################################

source ../terraform/.env
if [[ -z "${HCLOUD_TOKEN}" ]]; then
  echo "Error: Please provide HCLOUD_TOKEN in your .env file in root directory. Exiting"
  exit 1
fi

API_ENDPOINT="https://api.hetzner.cloud/v1"
CURL_ARGS=(
  -s  # Silent mode to suppress progress meter
  -H "Authorization: Bearer ${HCLOUD_TOKEN}"
)

for page_num in `seq 5`; do
  if [ $1 == "Images" ]; then
      echo "##### PAGE ${page_num} ######"
      curl "${CURL_ARGS[@]}" "${API_ENDPOINT}/images?page=${page_num}" | grep name
  elif [ $1 == "Servers" ]; then
      echo "##### PAGE ${page_num} ######"
      curl "${CURL_ARGS[@]}" "${API_ENDPOINT}/server_types?page=${page_num}" | jq -r '
        .server_types[] |
        select(.architecture == "x86") |
        select(.cpu_type     == "shared") |
        select(.category     == "cost_optimized") |
        select(.deprecated   == false) |
        {
          name:   .name,
          cores:  .cores,
          memory: .memory,
          disk:   .disk,

          prices_fsn1: (.prices | map(select(.location == "fsn1"))[0] // null)
        }
      '
  else
    echo "Error: Provide either Images or Servers as pos1 Variable to Bash script"
    exit 1
  fi
done