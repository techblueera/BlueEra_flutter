import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:get/get.dart';

/// The PHARMACY onboarding category and its sub-categories (Generic Medicine
/// Store, Medical Store, Online Pharmacy, Surgical Store, Medical Equipment
/// Shop).
///
/// Shared by the Discover Pharmacy section and `PharmacyStoresScreen`'s tab
/// strip so both show the same tiles, the same icons, and send the same ids —
/// tapping a Discover tile lands on the matching tab.
class PharmacySubCategories {
  const PharmacySubCategories._();

  /// Sub-category name → bundled icon, keyed lowercase.
  ///
  /// The API's [SubCategories] carries only `_id` and `name` — no image — so
  /// unlike the parent categories these can't take an icon from the response.
  /// Anything unmapped (i.e. a sub-category added server-side later) falls back
  /// to [fallbackIcon] so it still renders.
  static const Map<String, String> _icons = {
    'generic medicine store': 'assets/category/medical/generic_medicine_store.png',
    'medical store': 'assets/category/medical/medical_store.png',
    'online pharmacy': 'assets/category/medical/online_pharmacy.png',
    'surgical store': 'assets/category/medical/surgical_store.png',
    'medical equipment shop': 'assets/category/medical/medical_equipment_shop.png',
  };

  static const String fallbackIcon =
      'assets/category/medical/all_pharmacy.png';

  /// The PHARMACY entry of [AuthController]'s Healthcare bucket, or null before
  /// the onboarding categories load / if the backend stops sending it.
  static CategoryData? category() {
    final categories =
        Get.find<AuthController>().businessOnboardingHealthcareSectorsCategories;
    final index =
        categories.indexWhere((c) => (c.tagId ?? '').toUpperCase() == PHARMACY);
    return index == -1 ? null : categories[index];
  }

  /// Pharmacy's sub-categories — empty until the categories load.
  static List<SubCategories> all() =>
      category()?.subCategories ?? const <SubCategories>[];

  /// Section / screen title, straight from the API ("Pharmacy").
  static String title() => category()?.name ?? 'Pharmacy';

  static String iconFor(SubCategories sub) =>
      _icons[(sub.name ?? '').trim().toLowerCase()] ?? fallbackIcon;
}
