#!/usr/bin/env bash
# Pushes the "Profile Data" designation bottom-sheet strings
# (lib/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart)
# and the profile-type card labels it renders
# (lib/core/api/model/individual_profile_type_model.dart) to the language
# service. Also backfills gu/mr/kn for keys that had only shipped in en+hi.
# Regenerate the payloads with `python3 scripts/profile_designation_localization.py`.
# Run from the repo root:
#   bash scripts/profile_designation_lang_payloads/curl_commands.sh
set -e

for lang in en hi gu mr kn; do
  curl -X 'PUT' \
    "https://be.beapp.in/api/language-service/languages/$lang" \
    -H 'accept: */*' \
    -H 'Content-Type: application/json' \
    -d @scripts/profile_designation_lang_payloads/$lang.json
done
