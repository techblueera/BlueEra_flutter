#!/usr/bin/env bash
# Pushes the automotive-products customer (consumer) strings to the language
# service: 30 new keys per language, plus placeOrder / placeOrderCartWarning /
# noStoresFoundForCategory, which the screens referenced but which existed
# only in the local hi asset and nowhere on the server.
# Regenerate the payloads with:
#   python3 scripts/automotive_customer_localization.py
# Run from the repo root:
#   bash scripts/automotive_customer_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/automotive_customer_lang_payloads/$lang.json
done
