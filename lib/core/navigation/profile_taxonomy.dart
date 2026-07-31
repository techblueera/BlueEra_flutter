/// Fills in the routing taxonomy `openVisitProfile` branches on
/// (`type_of_business` / `profile_type`) for payloads that don't carry it.
///
/// The heavy profile endpoints return both halves, but the light list payloads
/// don't. `/feed` is the clearest case — its `user` object is only:
///
/// ```json
/// {"_id":"…","name":"Wrap Queen","account_type":"BUSINESS","designation":"Cloud kitchen mess",
///  "business_id":"…","business_name":"Wrap Queen","categoryOfBusiness":"Cloud kitchen mess"}
/// ```
///
/// — a sub-category and a designation, never `type_of_business` or
/// `profile_type`. Without those, every feed author would dead-end on the
/// generic profile screen.
///
/// The master category lists `AuthController` already fetches (and caches to
/// Hive, so they're populated on a cold start too) hold exactly the missing
/// link: each business category knows its `BusinessType`, each profession
/// knows its `IndividualProfileType`. So the taxonomy is *looked up* there
/// rather than hard-coded here — a second copy of that table would silently
/// drift the moment the backend adds a category.
///
/// Everything is matched on the normalised key, so the API's two spellings of
/// the same value — `"Cloud kitchen mess"` and `"CLOUD_KITCHEN_MESS"` — both
/// resolve.
library;

import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:get/get.dart';

/// Uppercases and collapses whitespace/hyphens to underscores:
/// `"Cloud kitchen mess"` → `CLOUD_KITCHEN_MESS`.
String normalizeTaxonomyKey(String? value) =>
    (value ?? '').trim().toUpperCase().replaceAll(RegExp(r'[\s\-/]+'), '_');

/// The feed serialises absent relations as the *string* `"null"` — an
/// individual arrives with `"business_id":"null"` and
/// `"categoryOfBusiness":"Null"`. Passing those through as real values routes
/// people to a business profile whose id is the literal text `null`, so every
/// entry point treats them as blank.
bool isBlankTaxonomyValue(String? value) {
  const blanks = {'', 'NULL', 'NONE', 'UNDEFINED', 'NA', 'N_A'};
  return blanks.contains(normalizeTaxonomyKey(value));
}

/// [value] when it holds something, else `null` — junk placeholders dropped.
String? cleanTaxonomyValue(String? value) =>
    isBlankTaxonomyValue(value) ? null : value!.trim();

/// The `BusinessType` name (`Food`, `Healthcare`, …) that owns [category]
/// (`"Cloud kitchen mess"`, `"DIAGNOSTIC"`, …), or `null` when the category is
/// unknown or the master lists haven't loaded yet — callers then fall back to
/// the generic business profile, exactly as before.
String? businessTypeForCategory(String? category) {
  final match = _findBusinessCategory(category);
  return match?.businessType?.name;
}

/// The canonical sub-category slug (`tag_id`) for [category], so a display
/// name (`"Non veg restaurant"`) reaches the visit resolver in the same shape
/// a profile endpoint would have sent (`NON_VEG_RESTAURANT`).
///
/// Falls back to the normalised input, which for BlueEra's naming already *is*
/// the slug in the overwhelming majority of cases.
String? canonicalBusinessCategory(String? category) {
  if (isBlankTaxonomyValue(category)) return null;
  final key = normalizeTaxonomyKey(category);
  final tag = normalizeTaxonomyKey(_findBusinessCategory(category)?.tagId);
  return tag.isNotEmpty ? tag : key;
}

/// The `IndividualProfileType` tag (`SELF_EMPLOYED` / `PROFESSIONAL` /
/// `GIG_WORKER` / `SOCIAL_PROFILE`) for [value], which may be:
///
/// * an already-canonical profile type — returned as-is;
/// * the API's display spelling of one (`"GigWork"`, `"Self Employed"`) — the
///   form `ProfessionTypeData.profileType` uses;
/// * a profession tag or its designation (`BIKE_RIDER`, `"Bike Rider"`,
///   `"Business Finance Consultant"`) — the only identity `/feed` gives,
///   looked up in the master profession list.
///
/// `null` when nothing matches, which leaves the caller on the generic visit
/// profile.
String? individualProfileTypeFor(String? value) {
  if (isBlankTaxonomyValue(value)) return null;
  final key = normalizeTaxonomyKey(value);

  // Direct / display spellings first — no controller needed, and it keeps
  // callers that already hold a real profile type working while the master
  // lists are still loading.
  final alias = _profileTypeAliases[key];
  if (alias != null) return alias;

  final controller = _auth;
  if (controller == null) return null;

  for (final bucket in [
    controller.individualOnboardingSkillWorkList,
    controller.individualOnboardingConsultationList,
    controller.individualOnboardingGigWorkList,
    controller.individualOnboardingSocialProfileList,
  ]) {
    for (final profession in bucket) {
      if (normalizeTaxonomyKey(profession.tagId) == key ||
          normalizeTaxonomyKey(profession.name) == key) {
        // `individualProfileType` is set while bucketing; the raw
        // `profileType` string is the fallback for a Hive-restored item that
        // hasn't been through that pass yet (enums don't round-trip JSON).
        return profession.individualProfileType?.tagId ??
            _profileTypeAliases[normalizeTaxonomyKey(profession.profileType)];
      }
    }
  }
  return null;
}

const Map<String, String> _profileTypeAliases = {
  'SELF_EMPLOYED': 'SELF_EMPLOYED',
  'SELFEMPLOYED': 'SELF_EMPLOYED',
  'SKILL_WORK': 'SELF_EMPLOYED',
  'SKILL_WORKER': 'SELF_EMPLOYED',
  'PROFESSIONAL': 'PROFESSIONAL',
  'CONSULTANT': 'PROFESSIONAL',
  'GIG_WORKER': 'GIG_WORKER',
  'GIGWORK': 'GIG_WORKER',
  'GIG_WORK': 'GIG_WORKER',
  'SOCIAL_PROFILE': 'SOCIAL_PROFILE',
  'SOCIALPROFILE': 'SOCIAL_PROFILE',
};

/// Master-list entry whose `tag_id` or display `name` matches [category].
CategoryData? _findBusinessCategory(String? category) {
  if (isBlankTaxonomyValue(category)) return null;
  final key = normalizeTaxonomyKey(category);
  final controller = _auth;
  if (controller == null) return null;

  for (final bucket in [
    controller.businessOnboardingFoodsCategories,
    controller.businessOnboardingGroceriesCategories,
    controller.businessOnboardingProductsCategories,
    controller.businessOnboardingManufacturingCategories,
    controller.businessOnboardingHealthcareSectorsCategories,
    controller.businessOnboardingEducationTrainingCategories,
    controller.businessOnboardingHospitalityStayCategories,
    controller.businessOnboardingFinancialSectorsCategories,
    controller.businessOnboardingAutomotiveServicesCategories,
    controller.businessOnboardingServicesCategories,
  ]) {
    for (final item in bucket) {
      if (normalizeTaxonomyKey(item.tagId) == key ||
          normalizeTaxonomyKey(item.name) == key) {
        return item;
      }
    }
  }
  return null;
}

/// `null` rather than throwing when the controller isn't up yet (cold-start
/// deep link, a widget test) — every lookup degrades to "unknown taxonomy".
AuthController? get _auth =>
    Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
