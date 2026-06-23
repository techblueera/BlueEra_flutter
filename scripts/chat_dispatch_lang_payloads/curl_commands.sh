#!/usr/bin/env bash
# Pushes the chat self-pickup → rider dispatch translation keys (Find Rider +
# rider OTP cards) to the language service. Run from the repo root:
#   bash scripts/chat_dispatch_lang_payloads/curl_commands.sh
set -e

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_dispatch_lang_payloads/en.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/hi' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_dispatch_lang_payloads/hi.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/gu' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_dispatch_lang_payloads/gu.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/mr' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_dispatch_lang_payloads/mr.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/kn' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/chat_dispatch_lang_payloads/kn.json
