#!/usr/bin/env bash
# Pushes the `healthCareList` category tile labels to the language service.
# Regenerate the payloads with `python3 scripts/healthcare_categories_localization.py`.
# Run from the repo root:
#   bash scripts/healthcare_categories_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/healthcare_categories_lang_payloads/$lang.json
done
