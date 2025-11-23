#!/usr/bin/env bash

if [[ -z $1 ]]
then
  echo "please provide an API_KEY"
  exit 1
fi

if [[ -z $2 ]]
then
  echo "no api endpoint supplied as script parameter. defaulting to hardcoded version"
  API_ENDPOINT="https://f8wnpdy1ab.execute-api.eu-central-1.amazonaws.com/api/fiscalismia/post/sheet_url/process_lambda/return_tsv_file_urls"
else
  API_ENDPOINT=$2
fi

if [[ -z $3 ]]
then
  echo "no sheet url provided. Set to default"
  SHEET_URL="https://docs.google.com/spreadsheets/d/e/2PACX-1vSVcmgixKaP9LC-rrqS4D2rojIz48KwKA8QBmJloX1h7f8BkUloVuiw19eR2U5WvVT4InYgnPunUo49/pub?output=xlsx"
else
  SHEET_URL=$3
fi

API_KEY=$1
curl "$API_ENDPOINT" \
  -H "Authorization: $API_KEY" \
  -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' \
  -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: cross-site' -H 'DNT: 1' -H 'Sec-GPC: 1' \
  -H 'TE: trailers' -H 'Priority: u=0, i' -H 'Origin: null' -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  --data-raw $SHEET_URL