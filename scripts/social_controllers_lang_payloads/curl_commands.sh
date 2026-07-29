#!/usr/bin/env bash
# Pushes the Social module controller strings
# (lib/features/me/social/controller/*.dart) to the language service: snackbar
# results, form validation copy, gu/mr/kn backfill for the two generic keys,
# and the "Something went wrong try after sometimes" fallback key that
# `AppStrings.somethingWentWrong.tr` resolves against app-wide.
# Regenerate the payloads with `python3 scripts/social_controllers_localization.py`.
# Run from the repo root:
#   bash scripts/social_controllers_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/social_controllers_lang_payloads/$lang.json
done
