#!/usr/bin/env bash
# Pushes the 4 new business Contact-Us card strings to the language service.
# Regenerate the payloads with:
#   python3 scripts/business_contact_card_localization.py
# Run from the repo root:
#   bash scripts/business_contact_card_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/business_contact_card_lang_payloads/$lang.json
done
