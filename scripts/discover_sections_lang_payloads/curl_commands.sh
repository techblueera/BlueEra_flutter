#!/usr/bin/env bash
# Pushes the Discover page section titles (Nearest Stores, Grocery & General
# Store, Restaurant & Food Service, Recently Visited Stores, Shopping & Sales,
# Home Services) and the rider store-link headers (Grocery & Stationary /
# Restaurant & Food) to the language service. Run from the repo root:
#   bash scripts/discover_sections_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/discover_sections_lang_payloads/$lang.json
done
