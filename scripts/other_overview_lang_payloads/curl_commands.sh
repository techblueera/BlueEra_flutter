#!/usr/bin/env bash
# Pushes the Others "Overview" tab strings
# (lib/features/me/others/view/v2/tabs/other_overview_tab_v2.dart) to the
# language service: section titles (Management, Career / Jobs, Timing,
# Add / Edit), the timing Open/Closed badges, and the Finance-only Banking
# Information card (RBI Registered, Account Types and each account type).
# Regenerate the payloads with `python3 scripts/other_overview_localization.py`.
# Run from the repo root:
#   bash scripts/other_overview_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/other_overview_lang_payloads/$lang.json
done
