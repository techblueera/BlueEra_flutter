#!/usr/bin/env bash
# Pushes the Social module screen strings (events / activities / achievements /
# vision-mission / certificates / contact-us / activity feed, under
# lib/features/me/social/view/) to the language service, plus gu/mr/kn backfill
# for keys that had only shipped in en+hi.
# Regenerate the payloads with `python3 scripts/social_screens_localization.py`.
# Run from the repo root:
#   bash scripts/social_screens_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/social_screens_lang_payloads/$lang.json
done
