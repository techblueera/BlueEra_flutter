import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:get/get.dart';

/// One row in the change-category picker, flattened from either catalog so the
/// screen doesn't branch on account type while it builds a list.
class CategoryOption {
  const CategoryOption({
    required this.tagId,
    required this.name,
    this.imageUrl,
    this.subCategories = const [],
  });

  /// The canonical `tag_id` — what gets submitted, and what is compared
  /// against `current.tag_id` for pre-selection.
  final String tagId;
  final String name;
  final String? imageUrl;

  /// BUSINESS only. A category with sub-categories needs one chosen, otherwise
  /// the change clears `sub_category_Of_Business` and leaves the merchant with
  /// a category but no sub-category.
  final List<CategorySubOption> subCategories;

  bool get hasSubCategories => subCategories.isNotEmpty;

  /// The six business categories the backend requires a licence number for.
  /// Matched on the token because the category arrives in several shapes.
  bool get requiresLicense {
    final key = tagId.toUpperCase();
    return key.contains(BusinessCategoryTokens.pharmacy) ||
        key.contains(BusinessCategoryTokens.hospitals) ||
        key.contains(BusinessCategoryTokens.clinicToken) ||
        key.contains(BusinessCategoryTokens.doctorToken) ||
        key.contains(BusinessCategoryTokens.diagnostic) ||
        key.contains('ALTERNATIVE');
  }
}

class CategorySubOption {
  const CategorySubOption({required this.id, required this.name});
  final String id;
  final String name;
}

/// Builds the picker's list from the catalogs the app has ALREADY loaded and
/// cached (`AuthController.loadCategoriesCacheFirstThenRefresh`), rather than
/// calling the catalog endpoints again.
///
/// That choice also answers §6's warning about exposing professions the app
/// can't handle: these are the same buckets ONBOARDING picks from, so anything
/// offered here is something the app could already have created an account as.
/// A profession the server adds but doesn't bucket never reaches the picker.
class CategoryOptionsSource {
  const CategoryOptionsSource._();

  static AuthController? get _auth =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  /// INDIVIDUAL — every profession across the four onboarding buckets.
  ///
  /// Retired (`isActive: false`) and soft-deleted rows are dropped here: the
  /// professions endpoint returns them and the change endpoint rejects them
  /// with `422 unknown_category`, so leaving them in offers options that
  /// always fail.
  static List<CategoryOption> professions() {
    final auth = _auth;
    if (auth == null) return const [];
    return [
      ...auth.individualOnboardingSocialProfileList,
      ...auth.individualOnboardingGigWorkList,
      ...auth.individualOnboardingSkillWorkList,
      ...auth.individualOnboardingConsultationList,
    ]
        .where((p) => p.isSelectable)
        .where((p) => (p.tagId ?? '').isNotEmpty)
        .map(_fromProfession)
        .toList();
  }

  /// BUSINESS — every category across the ten onboarding buckets.
  ///
  /// No active/deleted filter: `GET business/getAllcategories` already filters
  /// to `active: true` server-side.
  static List<CategoryOption> businessCategories() {
    final auth = _auth;
    if (auth == null) return const [];
    return [
      ...auth.businessOnboardingFoodsCategories,
      ...auth.businessOnboardingGroceriesCategories,
      ...auth.businessOnboardingProductsCategories,
      ...auth.businessOnboardingManufacturingCategories,
      ...auth.businessOnboardingHealthcareSectorsCategories,
      ...auth.businessOnboardingEducationTrainingCategories,
      ...auth.businessOnboardingHospitalityStayCategories,
      ...auth.businessOnboardingFinancialSectorsCategories,
      ...auth.businessOnboardingAutomotiveServicesCategories,
      ...auth.businessOnboardingServicesCategories,
    ]
        .where((c) => (c.tagId ?? '').isNotEmpty)
        .map(_fromBusinessCategory)
        .toList();
  }

  static CategoryOption _fromProfession(ProfessionTypeData p) => CategoryOption(
        tagId: p.tagId!,
        name: p.name ?? p.tagId!,
        imageUrl: p.imageUrl,
      );

  static CategoryOption _fromBusinessCategory(CategoryData c) => CategoryOption(
        tagId: c.tagId!,
        name: c.name ?? c.tagId!,
        imageUrl: c.imageUrl,
        subCategories: (c.subCategories ?? [])
            .where((s) => (s.sId ?? '').isNotEmpty)
            .map((s) => CategorySubOption(id: s.sId!, name: s.name ?? ''))
            .toList(),
      );
}
