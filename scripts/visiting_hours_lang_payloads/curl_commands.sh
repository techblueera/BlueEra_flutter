#!/usr/bin/env bash
# Pushes the redesigned visiting-hours selector + business-hours sheet strings
# to the language service.
# Regenerate the payloads with `python3 scripts/visiting_hours_localization.py`.
# Run from the repo root:
#   bash scripts/visiting_hours_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/visiting_hours_lang_payloads/$lang.json
done
