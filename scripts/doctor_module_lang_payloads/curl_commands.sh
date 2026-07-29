#!/usr/bin/env bash
# Pushes the standalone-doctor module strings (lib/features/me/doctor/) to the
# language service, plus gu/mr/kn backfill for `read_less` and `retry`.
# Regenerate the payloads with `python3 scripts/doctor_module_localization.py`.
# Run from the repo root:
#   bash scripts/doctor_module_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/doctor_module_lang_payloads/$lang.json
done
