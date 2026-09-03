#!/usr/bin/env bash
# Pushes the spelling / grammar corrections to the language API.
#
# English only: the pass corrected English copy, so no other locale's values
# changed. Merges into the existing map — keys not listed are left alone.
set -e

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/copy_fixes_lang_payloads/en.json
