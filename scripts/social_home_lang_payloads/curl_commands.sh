#!/usr/bin/env bash
# Pushes the Social home screen strings
# (lib/features/me/social/view/social_home_screen.dart) to the language
# service: the "Latest Post" chapter title, the ten per-section empty-state
# messages, and gu/mr/kn backfill for the section titles, Reception row,
# post-action row and relative-timestamp units.
# Regenerate the payloads with `python3 scripts/social_home_localization.py`.
# Run from the repo root:
#   bash scripts/social_home_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/social_home_lang_payloads/$lang.json
done
