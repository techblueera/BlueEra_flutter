#!/usr/bin/env bash
# Pushes the Discover doctor public profile strings to the language service,
# plus the gu/mr/kn backfill for `yearLabel`.
# Regenerate the payloads with `python3 scripts/doctor_public_profile_localization.py`.
# Run from the repo root:
#   bash scripts/doctor_public_profile_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/doctor_public_profile_lang_payloads/$lang.json
done
