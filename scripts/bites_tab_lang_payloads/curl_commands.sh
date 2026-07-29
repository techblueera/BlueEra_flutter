#!/usr/bin/env bash
# Pushes the order/chat main feed TabBar labels
# (lib/features/chat/view/order_main_chat_screen.dart) to the language service:
# the new `bites` reels-tab label plus gu/mr/kn backfill for the sibling
# `social` / `community` tabs.
# Regenerate the payloads with `python3 scripts/bites_tab_localization.py`.
# Run from the repo root:
#   bash scripts/bites_tab_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/bites_tab_lang_payloads/$lang.json
done
