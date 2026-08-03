#!/usr/bin/env bash
# Pushes the automotive-products admin (merchant) strings to the language
# service: ~70 new keys per language, plus the addProducts / category / off
# backfills for the languages that were missing them.
# Regenerate the payloads with:
#   python3 scripts/automotive_admin_localization.py
# Run from the repo root:
#   bash scripts/automotive_admin_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/automotive_admin_lang_payloads/$lang.json
done
