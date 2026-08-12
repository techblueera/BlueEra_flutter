import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:get/get.dart';

/// The `tag_id` the account-plan catalog is scoped to.
///
/// ## Why this is not just `businessCategoryGlobal`
///
/// That global holds the category's **display name** — "General Store" — but
/// the catalog keys on the tag id, `GENERAL_STORE`. Sending the name produced
/// `?tag_id=General+Store`, which the backend cannot resolve.
///
/// Individuals are unaffected: `userProfessionGlobal` already holds a tag id
/// (`BIKE_RIDER`), which is why the gig catalog worked while the shop one
/// did not.
///
/// The name is resolved back to its id against the same onboarding category
/// list the backend serves, so the value is the backend's own rather than
/// something this app invented.
class AccountPlanTag {
  const AccountPlanTag._();

  /// Tag id for the signed-in account, or `''` when it cannot be resolved
  /// (the catalog then falls back to the profile server-side for individuals,
  /// and reports "no plans" for a business).
  static String resolve() {
    if (!isBusinessUser()) return userProfessionGlobal;

    final name = businessCategoryGlobal.trim();
    if (name.isEmpty) return '';

    // Already an id — the global is populated from more than one place, and
    // some paths do store the tag.
    if (_looksLikeTagId(name)) return name;

    return _lookUpByName(name) ?? _slugify(name);
  }

  /// Upper snake case with no spaces, e.g. `GENERAL_STORE`.
  static bool _looksLikeTagId(String value) =>
      !value.contains(' ') && value == value.toUpperCase();

  /// Finds the category whose name matches, across every business bucket.
  ///
  /// Returns null when the categories have not loaded yet (a cold start that
  /// went straight to this screen) — the caller then falls back to slugifying.
  static String? _lookUpByName(String name) {
    if (!Get.isRegistered<AuthController>()) return null;
    final auth = Get.find<AuthController>();
    final buckets = <List<CategoryData>>[
      auth.businessOnboardingGroceriesCategories,
      auth.businessOnboardingFoodsCategories,
      auth.businessOnboardingProductsCategories,
      auth.businessOnboardingServicesCategories,
      auth.businessOnboardingAutomotiveServicesCategories,
      auth.businessOnboardingHealthcareSectorsCategories,
      auth.businessOnboardingHospitalityStayCategories,
      auth.businessOnboardingEducationTrainingCategories,
      auth.businessOnboardingFinancialSectorsCategories,
      auth.businessOnboardingManufacturingCategories,
    ];
    final target = _normalise(name);
    for (final bucket in buckets) {
      for (final category in bucket) {
        final tag = category.tagId;
        if (tag == null || tag.isEmpty) continue;
        if (_normalise(category.name ?? '') == target) return tag;
      }
    }
    return null;
  }

  /// Category names carry line breaks for pill layout ("Grocery\n& Stationary")
  /// and inconsistent spacing, so both sides are flattened before comparing.
  static String _normalise(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  /// Last resort when the master list is not loaded: the tag ids follow upper
  /// snake case of the name, so "General Store" → "GENERAL_STORE". A guess,
  /// but a far better one than sending the display name unchanged.
  static String _slugify(String name) => name
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .toUpperCase();
}
