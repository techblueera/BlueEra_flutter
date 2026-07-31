#!/usr/bin/env bash
# Pushes the full referral-module string set to the language service:
# the screens/tabs keys plus the widgets keys, and the gu/mr/kn backfill
# for shared keys (history, withdraw, balance, totalEarn, estdEarning,
# joiningBonus, bonusLabel, filterLabel, labelName, professionLabel,
# noTestimonialsYet, export, applyLabel, copiedLabel).
# Regenerate the payloads with:
#   python3 scripts/referral_module_localization.py
# Run from the repo root:
#   bash scripts/referral_module_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/referral_module_lang_payloads/$lang.json
done
