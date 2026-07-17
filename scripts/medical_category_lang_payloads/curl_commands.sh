#!/usr/bin/env bash
set -e

# Heading over the category grid on the medical snap-search screen
# (lib/features/me/medical/view/add_medical_snap_search_screen.dart).
#
# Replaces the old `medicalChooseYourMedicalProducts` ("Choose your medical
# products"). That key is left on the language service untouched — nothing in
# the app reads it any more.
#
# Only en.json here. The key also lives in assets/translations/en.json, which
# the localization service loads as the 'en' fallback layer, so every locale
# renders the English copy rather than a raw key until translations land. To
# localise, add <lang>.json beside en.json, append a PUT below, then
# `dart run scripts/sync_translations.dart`.

curl -X 'PUT' \
  'https://be.beapp.in/api/language-service/languages/en' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d @scripts/medical_category_lang_payloads/en.json
