#!/usr/bin/env bash
# Pushes the customer-side doctor booking strings to the language service,
# plus the `bookAppointment` (en/hi) and `optionalLabel` (hi/gu/mr/kn) backfill.
# Regenerate the payloads with `python3 scripts/doctor_booking_localization.py`.
# Run from the repo root:
#   bash scripts/doctor_booking_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/doctor_booking_lang_payloads/$lang.json
done
