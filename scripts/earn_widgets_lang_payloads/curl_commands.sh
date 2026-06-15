#!/usr/bin/env bash
set -e

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/en.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/hi' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/hi.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/gu' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/gu.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/mr' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/mr.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/kn' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/kn.json

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/bn' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/earn_widgets_lang_payloads/bn.json
