#!/usr/bin/env bash
set -e

# Strings for the once-a-day merchant add-product prompt
# (lib/widgets/add_product_prompt_sheet.dart).
#
# Only en.json is pushed here. The other languages are deliberately NOT
# included: the keys also live in assets/translations/en.json, which the
# localization service loads as the 'en' fallback layer, so every locale
# renders the English copy instead of a raw key until real translations land.
# To localise, add <lang>.json next to en.json, append a PUT below, then
# `dart run scripts/sync_translations.dart` to pull the values back into
# assets/translations/.

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/add_product_prompt_lang_payloads/en.json
