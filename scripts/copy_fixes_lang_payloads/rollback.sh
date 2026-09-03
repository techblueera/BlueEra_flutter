#!/usr/bin/env bash
# Restores the PRE-FIX server values for every key the push touched, captured
# from GET /language-service/languages/en immediately before the push.
# Only run this to undo scripts/copy_fixes_lang_payloads/curl_commands.sh.
set -e

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/copy_fixes_lang_payloads/en_rollback.json
