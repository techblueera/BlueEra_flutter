#!/usr/bin/env bash
# Pushes the global-search screen strings (category chips, landing
# sections, sort sheet, result cards, empty/error states) to the
# language service. Run from the repo root:
#   bash scripts/global_search_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/global_search_lang_payloads/$lang.json
done
