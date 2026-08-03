#!/usr/bin/env bash
# Pushes the "Post Via" chooser option subtitles to the language service, in
# all five languages.
# Regenerate the payloads with:
#   python3 scripts/post_via_dialog_localization.py
# Run from the repo root:
#   bash scripts/post_via_dialog_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/post_via_dialog_lang_payloads/$lang.json
done
