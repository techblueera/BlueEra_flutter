#!/usr/bin/env bash
# Pushes the referral share card strings to the language service: the two-line
# headline (with its {highlight} marker) and the share-via label, in all five
# languages.
# Regenerate the payloads with:
#   python3 scripts/referral_share_card_localization.py
# Run from the repo root:
#   bash scripts/referral_share_card_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/referral_share_card_lang_payloads/$lang.json
done
