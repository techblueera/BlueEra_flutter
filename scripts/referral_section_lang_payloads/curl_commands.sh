#!/usr/bin/env bash
# Pushes the referral card + "Update Referral Code" strings to the language
# service: 2 new keys everywhere, plus the 7-key gu/mr/kn backfill for the
# referral card labels that had only ever shipped in en/hi.
# Regenerate the payloads with:
#   python3 scripts/referral_section_localization.py
# Run from the repo root:
#   bash scripts/referral_section_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/referral_section_lang_payloads/$lang.json
done
