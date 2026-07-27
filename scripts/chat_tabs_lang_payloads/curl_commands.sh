#!/usr/bin/env bash
# Pushes the chat list tab labels (All / Pinned / Reminder / Flagged / Records /
# History) used by business, personal and group chat lists to the language
# service. Run from the repo root:
#   bash scripts/chat_tabs_lang_payloads/curl_commands.sh
set -e

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_tabs_lang_payloads/en.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/hi' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_tabs_lang_payloads/hi.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/gu' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_tabs_lang_payloads/gu.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/mr' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_tabs_lang_payloads/mr.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/kn' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_tabs_lang_payloads/kn.json
