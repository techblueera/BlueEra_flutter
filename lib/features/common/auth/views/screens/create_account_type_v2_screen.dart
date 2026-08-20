import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/model/personal_profession_model.dart';
import 'package:BlueEra/features/common/auth/views/screens/Individual/gig_work_aadhaar_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';

// Only the leave-this-screen confirmation used this — restore it alongside
// `_confirmExit` below if the dialog ever comes back.
// import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Screen text now goes through AppStrings keys + GetX `.tr` (asset JSON +
// language pack + `en` fallback) instead of LanguageListController.tr, which
// resolved only against the downloaded pack.
import '../../model/get_categories_model.dart';

/// The six top-level "How You Earn" options shown on the first screen.
/// Each maps to a set of onboarding category buckets already loaded by
/// [AuthController]. See [_earnConfig] for the mapping.
enum _EarnType {
  businessShop,
  businessStore,
  selfWork,
  gigWork,
  notEarning,
  doingJob,
  manufacturing,
}

/// True when the earn type resolves to BUSINESS category buckets
/// (`CategoryData`); false when it resolves to INDIVIDUAL profession
/// buckets (`ProfessionTypeData`).
bool _isBusinessEarnType(_EarnType type) =>
    type == _EarnType.businessShop ||
    type == _EarnType.businessStore ||
    type == _EarnType.manufacturing;

/// Static presentation config for a "How You Earn" row.
///
/// [title] and [subtitle] are TRANSLATION KEYS ([AppStrings]), not display
/// text. Every widget that renders them ([CustomText], [CommonBackAppBar])
/// applies `.tr` itself, so they translate wherever they are shown without the
/// call site remembering to do it.
class _EarnConfig {
  final String title;
  final String subtitle;
  final String icon;

  const _EarnConfig(this.title, this.subtitle, this.icon);
}

const Map<_EarnType, _EarnConfig> _earnConfig = {
  _EarnType.businessShop: _EarnConfig(
    AppStrings.earnBusinessShop,
    AppStrings.earnBusinessShopSub,
    "assets/onboarding/onboring_business.png",
  ),
  _EarnType.businessStore: _EarnConfig(
    AppStrings.earnBusinessStore,
    AppStrings.earnBusinessStoreSub,
    "assets/onboarding/onbording_store.png",
  ),
  _EarnType.selfWork: _EarnConfig(
    AppStrings.earnSelfWork,
    AppStrings.earnSelfWorkSub,
    "assets/onboarding/onbording_self_work.png",
  ),
  _EarnType.gigWork: _EarnConfig(
    AppStrings.earnGigWork,
    AppStrings.earnGigWorkSub,
    "assets/onboarding/onbording_gig_worker.png",
  ),
  _EarnType.notEarning: _EarnConfig(
    AppStrings.earnNotEarning,
    AppStrings.earnNotEarningSub,
    "assets/onboarding/onbording_not_earning.png",
  ),
  _EarnType.doingJob: _EarnConfig(
    AppStrings.earnDoingJob,
    AppStrings.earnDoingJobSub,
    "assets/onboarding/onbording_doing_a_job.png",
  ),
  _EarnType.manufacturing: _EarnConfig(
    AppStrings.earnManufacturing,
    AppStrings.earnManufacturingSub,
    "assets/onboarding/onbording_manufacturing.png",
  ),
};

/// ---------------------------------------------------------------------------
/// SCREEN 1 — "Choose Your Account Type" → "How You Earn" list.
///
/// A fresh, non-tabbed re-implementation of the onboarding entry screen based
/// on the reference PDF. It reuses every existing [AuthController] category
/// bucket and downstream navigation, so the legacy [CreateAccountTypeScreen]
/// keeps working untouched.
/// ---------------------------------------------------------------------------
class CreateAccountTypeV2Screen extends StatefulWidget {
  final String? accountType;

  const CreateAccountTypeV2Screen({super.key, this.accountType});

  @override
  State<CreateAccountTypeV2Screen> createState() =>
      _CreateAccountTypeV2ScreenState();
}

class _CreateAccountTypeV2ScreenState extends State<CreateAccountTypeV2Screen> {
  final authController = getOrPut(() => AuthController());

  @override
  void initState() {
    super.initState();
    // Same cache-first master-list load the legacy screen uses; the second
    // screen reads the resulting buckets.
    authController.loadCategoriesCacheFirstThenRefresh();
  }

  List<_EarnType> get _rows {
    // Honour the optional accountType filter used by some call sites: only
    // business-kind rows for BUSINESS, only individual rows for INDIVIDUAL.
    if (widget.accountType == AppConstants.business) {
      return _EarnType.values.where(_isBusinessEarnType).toList();
    }
    if (widget.accountType == AppConstants.individual) {
      return _EarnType.values.where((t) => !_isBusinessEarnType(t)).toList();
    }
    return _EarnType.values;
  }

  /* Back is a plain pop now — see the note on [build].
  /// Confirmation dialog shown for every exit attempt — mirrors the legacy
  /// screen so backing out of account creation always lands on home.
  void _confirmExit() {
    commonConformationDialog(
      context: context,
      text: langController.tr('Are you sure you want to leave this screen?'),
      confirmCallback: () {
        Navigator.of(context, rootNavigator: true).pop();
        Get.offAllNamed(RouteHelper.getBottomNavigationBarScreenRoute());
      },
      cancelCallback: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }
  */

  void _openCategoryScreen(_EarnType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AccountCategoryScreen(earnType: type),
      ),
    );
  }

  /// Back — system gesture, hardware button and the app bar arrow alike — is a
  /// plain pop, so the user lands back wherever they opened this from.
  ///
  /// It used to be wrapped in a [PopScope] with `canPop: false` that asked "Are
  /// you sure you want to leave this screen?" and, on confirm, cleared the
  /// whole stack to the bottom nav. Nothing has been entered on this screen —
  /// it's a list of links — so there was no work to lose and nothing to
  /// confirm; and dropping the stack sent people who arrived from Discover or a
  /// profile back to home instead of to what they were looking at.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: CommonBackAppBar(
        isLeading: true,
        appBarColor: Colors.white,
        title: AppStrings.chooseYourAccountType,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16,
              vertical: SizeConfig.size20,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(SizeConfig.size16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.accountTypeHowYouEarn,
                  fontSize: SizeConfig.size24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  AppStrings.accountTypeSelectProfession,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                ),
                SizedBox(height: SizeConfig.size16),
                for (final type in _rows) ...[
                  _earnRow(type),
                  SizedBox(height: SizeConfig.size12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _earnRow(_EarnType type) {
    final config = _earnConfig[type]!;
    return InkWell(
      borderRadius: BorderRadius.circular(SizeConfig.size12),
      onTap: () => _openCategoryScreen(type),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14,
          vertical: SizeConfig.size14,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: Row(
          children: [
            Container(
              height: SizeConfig.size44,
              width: SizeConfig.size44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.skyBlueE4,
                shape: BoxShape.circle,
              ),
              child: LocalAssets(
                imagePath: config.icon,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    config.title,
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size2),
                  CustomText(
                    config.subtitle,
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff66727E),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.secondaryTextColor,
              size: SizeConfig.size22,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SCREEN 2 — sectioned category pills for the chosen earn type.
///
/// Pill icons are rendered from the API `image_url` on each category /
/// profession. Selecting a pill (business) opens a sub-category sheet when the
/// category has one; "Next" reuses the exact legacy downstream navigation.
/// ---------------------------------------------------------------------------
class _AccountCategoryScreen extends StatefulWidget {
  final _EarnType earnType;

  const _AccountCategoryScreen({required this.earnType});

  @override
  State<_AccountCategoryScreen> createState() => _AccountCategoryScreenState();
}

class _AccountCategoryScreenState extends State<_AccountCategoryScreen> {
  final authController = getOrPut(() => AuthController());

  /// `CategoryData` (business) or `ProfessionTypeData` (individual).
  final Rxn<Object> selectedItem = Rxn<Object>();

  /// Sub-category picked alongside a business pill. Null for individual pills,
  /// manufacturing, or categories without sub-categories.
  final Rxn<SubCategories> selectedSubCategory = Rxn<SubCategories>();

  bool get _isBusiness => _isBusinessEarnType(widget.earnType);

  @override
  void initState() {
    super.initState();
    // Keep the parent-slug state consistent with the legacy flow so any
    // downstream reader sees the right value.
    authController.selectedParentSlug.value =
        _isBusiness ? AppConstants.business : AppConstants.individual;
    if (_isBusiness) {
      authController.selectedIndividualOnboardingProfile.value = null;
    } else {
      authController.selectedBusinessOnboardingProfile.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _earnConfig[widget.earnType]!;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        isLeading: true,
        appBarColor: Colors.white,
        title: config.title,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF1F5FB),
                child: Obx(() {
                  // Subscribe to bucket changes so the silent network refresh
                  // repaints the grid, and to the selection Rx so pill
                  // highlight updates.
                  authController.onboardingBucketsWatch;
                  selectedItem.value;
                  if (authController.isInitialCategoriesLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      SizeConfig.size16,
                      SizeConfig.size16,
                      SizeConfig.size16,
                      SizeConfig.size20,
                    ),
                    child: _isBusiness ? _businessBody() : _individualBody(),
                  );
                }),
              ),
            ),
            _buildBottomNext(),
          ],
        ),
      ),
    );
  }

  // --- Business ------------------------------------------------------------

  /// Section titles are [AppStrings] keys — [_sectionCard] renders them through
  /// [CustomText], which translates.
  List<_Section> _businessSections() {
    if (widget.earnType == _EarnType.manufacturing) {
      return [
        _Section(
          title: AppStrings.accountSectionManufacturing,
          items: authController.businessOnboardingManufacturingCategories,
        ),
      ];
    }
    // businessShop / businessStore → every business bucket except
    // manufacturing (and except finance on the Non-GST row, below).
    return [
      _Section(
        title: AppStrings.accountSectionGrocery,
        items: authController.businessOnboardingGroceriesCategories,
      ),
      _Section(
        title: AppStrings.accountSectionFood,
        items: authController.businessOnboardingFoodsCategories,
      ),
      _Section(
        title: AppStrings.accountSectionShopStore,
        items: authController.businessOnboardingProductsCategories,
      ),
      _Section(
        title: AppStrings.accountSectionServices,
        items: authController.businessOnboardingServicesCategories,
      ),
      _Section(
        title: AppStrings.accountSectionAutomotive,
        items: authController.businessOnboardingAutomotiveServicesCategories,
      ),
      _Section(
        title: AppStrings.accountSectionHealthCare,
        items: authController.businessOnboardingHealthcareSectorsCategories,
      ),
      _Section(
        title: AppStrings.accountSectionHospitality,
        items: authController.businessOnboardingHospitalityStayCategories,
      ),
      if (widget.earnType == _EarnType.businessStore)
        _Section(
          title: AppStrings.accountSectionEducation,
          items: authController.businessOnboardingEducationTrainingCategories,
        ),
      // Banking / finance is a GST-registered vertical, so the whole Financial
      // Sectors bucket is offered on Business/Shop (GST) only — the Non-GST
      // small-shop row must not be able to onboard as a finance business.
      // Manufacturing never reaches here (it returns its own section above).
      if (widget.earnType != _EarnType.businessStore)
        _Section(
          title: AppStrings.accountSectionFinancial,
          items: authController.businessOnboardingFinancialSectorsCategories,
        ),
    ];
  }

  Widget _businessBody() {
    final nonEmpty =
        _businessSections().where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: AppStrings.accountTypeNoCategory);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in nonEmpty) ...[
          _sectionCard(
            title: section.title,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: SizeConfig.size10,
              runSpacing: SizeConfig.size12,
              children: section.items.map(_businessPill).toList(),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
        ],
      ],
    );
  }

  Widget _businessPill(CategoryData c) {
    final selected = identical(selectedItem.value, c);
    return _pill(
      label: c.name ?? '',
      iconUrl: c.imageUrl,
      selected: selected,
      onTap: () => _onBusinessPillTap(c),
    );
  }

  Future<void> _onBusinessPillTap(CategoryData c) async {
    if (c.businessType == BusinessType.Manufacturing) {
      selectedItem.value = c;
      selectedSubCategory.value = null;
      return;
    }
    final tagId = c.tagId;
    if (tagId == null) {
      selectedItem.value = c;
      selectedSubCategory.value = null;
      return;
    }
    final picked = await showModalBottomSheet<_SubCategoryPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessSubCategoryBottomSheet(
        authController: authController,
        categorySlugId: tagId,
        categoryName: c.name ?? '',
      ),
    );
    if (picked == null) return; // dismissed
    selectedItem.value = c;
    selectedSubCategory.value = picked.subCategory;
  }

  // --- Individual ----------------------------------------------------------

  List<_IndividualSection> _individualSections() {
    switch (widget.earnType) {
      case _EarnType.selfWork:
        return [
          _IndividualSection(
            title: AppStrings.accountSectionSkillWork,
            items: authController.individualOnboardingSkillWorkList,
          ),
          _IndividualSection(
            title: AppStrings.accountSectionConsultant,
            items: authController.individualOnboardingConsultationList,
          ),
        ];
      case _EarnType.gigWork:
        return [
          _IndividualSection(
            title: AppStrings.accountSectionSelfEmployed,
            items: authController.individualOnboardingGigWorkList,
          ),
        ];
      case _EarnType.notEarning:
      case _EarnType.doingJob:
        return [
          _IndividualSection(
            title: AppStrings.accountSectionSocialProfile,
            items: authController.individualOnboardingSocialProfileList,
          ),
        ];
      case _EarnType.businessShop:
      case _EarnType.businessStore:
      case _EarnType.manufacturing:
        return const [];
    }
  }

  Widget _individualBody() {
    final nonEmpty =
        _individualSections().where((s) => s.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return EmptyStateWidget(message: AppStrings.accountTypeNoProfession);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in nonEmpty) ...[
          _sectionCard(
            title: section.title,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: SizeConfig.size10,
              runSpacing: SizeConfig.size12,
              children: section.items.map(_individualPill).toList(),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
        ],
      ],
    );
  }

  Widget _individualPill(ProfessionTypeData p) {
    final selected = identical(selectedItem.value, p);
    return _pill(
      label: p.name ?? '',
      iconUrl: p.imageUrl,
      selected: selected,
      onTap: () {
        selectedItem.value = p;
        selectedSubCategory.value = null;
      },
    );
  }

  // --- Shared UI -----------------------------------------------------------

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(SizeConfig.size16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomText(
            title,
            fontSize: SizeConfig.size16,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size12),
          child,
        ],
      ),
    );
  }

  /// Pill with an API-driven leading icon (`image_url`).
  Widget _pill({
    required String label,
    required String? iconUrl,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(SizeConfig.size30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size30),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pillIcon(iconUrl, selected),
            SizedBox(width: SizeConfig.size6),
            CustomText(
              label,
              fontSize: 13.0,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.white : AppColors.mainTextColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the category icon from the API `image_url`. Falls back to a
  /// neutral glyph when no URL is provided or the image fails to load.
  Widget _pillIcon(String? url, bool selected) {
    final double size = SizeConfig.size18;
    final Color fallbackColor =
        selected ? AppColors.white : AppColors.secondaryTextColor;
    if (url == null || url.trim().isEmpty) {
      return Icon(Icons.category_outlined, size: size, color: fallbackColor);
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: size,
      width: size,
      fit: BoxFit.contain,
      placeholder: (context, _) => SizedBox(height: size, width: size),
      errorWidget: (context, _, __) =>
          Icon(Icons.category_outlined, size: size, color: fallbackColor),
    );
  }

  Widget _buildBottomNext() {
    return Material(
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size20,
            vertical: SizeConfig.size12,
          ),
          child: Obx(() {
            final canProceed = selectedItem.value != null;
            return CustomBtn(
              radius: SizeConfig.size30,
              isValidate: canProceed,
              bgColor: canProceed ? AppColors.primaryColor : AppColors.whiteF3,
              textColor: canProceed ? AppColors.white : AppColors.grey9B,
              title: AppStrings.next,
              onTap: canProceed ? _onNext : null,
            );
          }),
        ),
      ),
    );
  }

  void _onNext() {
    final item = selectedItem.value;
    if (item == null) return;
    if (item is CategoryData) {
      final type = item.businessType;
      final tagId = item.tagId;
      final name = item.name;
      if (type == null || tagId == null || name == null) return;

      // Small Business/Shop (NON GST) never sees the GST screen. The row is the
      // user saying they have no GST, so asking again on the next screen is the
      // same question twice — they go straight to the account form.
      //
      // The GST screen is not only about GST though: its initState is what
      // hands the chosen category to [AuthController], which every later step
      // (the summary card on step one, the create payload on step four) reads.
      // Skipping the screen means doing that here, or the category is lost.
      //
      // The GST flags are reset for the same reason the screen's own "No I
      // don't" / Skip paths reset them: `isHaveGstApprove` is what LOCKS the
      // business name and address on step one to the GST-verified values, and
      // it is a permanent controller, so a GST attempt earlier in this session
      // would otherwise leave those fields locked to the wrong business.
      if (widget.earnType == _EarnType.businessStore) {
        authController
          ..selectedTypeOfBusiness = type
          ..selectedCategoryName = name
          ..selectedCategorySlugId = tagId
          ..selectedSubCategoryData = selectedSubCategory.value;
        authController.hasGstNumber.value = false;
        authController.isHaveGstApprove.value = false;
        authController.isValidate.value = false;
        Get.toNamed(RouteHelper.getCreateBusinessAccountNewStepOneRoute());
        return;
      }

      Navigator.pushNamed(
        context,
        RouteHelper.getGstNumberScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: AppConstants.business,
          ApiKeys.argBusinessType: type,
          ApiKeys.argCategoryId: tagId,
          ApiKeys.argCategoryName: name,
          ApiKeys.argSubCategory: selectedSubCategory.value,
          // Business/Shop (GST) → GST is compulsory. Small Business/Shop
          // (Non GST) and Manufacturing keep GST optional.
          ApiKeys.argIsGstMandatory: widget.earnType == _EarnType.businessShop,
        },
      );
    } else if (item is ProfessionTypeData) {
      log('---------------- LOG DATA ----------------');
      log('${ApiKeys.argProfileType} : ${item.individualProfileType?.tagId}');
      log('${ApiKeys.argProfessionTagId}    : ${item.tagId}');
      log('${ApiKeys.argProfession}    : ${item.name}');

      final profileType = item.individualProfileType;
      final professionTagId = item.tagId;
      final profession = item.name;

      // Gig work goes through Aadhaar FIRST — it puts someone in a customer's
      // vehicle or at their door, so the identity is established before the
      // profile exists rather than as a document uploaded later. That screen
      // owns the hop to the profile form and carries the verified name and
      // date of birth into it. Every other profession still goes straight
      // through, and rider onboarding is unaffected.
      if (widget.earnType == _EarnType.gigWork &&
          profileType != null &&
          professionTagId != null &&
          profession != null) {
        Get.to(
          () => GigWorkAadhaarScreen(
            accountType: AppConstants.individual,
            profileType: profileType,
            profession: profession,
            professionTagId: professionTagId,
          ),
        );
        return;
      }

      Get.toNamed(
        RouteHelper.getPersonalAccountNewScreenRoute(),
        arguments: {
          ApiKeys.argAccountType: AppConstants.individual,
          ApiKeys.argProfileType: item.individualProfileType,
          ApiKeys.argProfessionTagId: item.tagId,
          ApiKeys.argProfession: item.name,
        },
      );
    }
  }
}

class _Section {
  final String title;
  final List<CategoryData> items;

  _Section({required this.title, required this.items});
}

class _IndividualSection {
  final String title;
  final List<ProfessionTypeData> items;

  _IndividualSection({required this.title, required this.items});
}

class _SubCategoryPickResult {
  final SubCategories? subCategory;

  _SubCategoryPickResult(this.subCategory);
}

/// Self-contained copy of the legacy business sub-category picker so this new
/// flow stays fully decoupled from `create_account_type_screen.dart`.
class _BusinessSubCategoryBottomSheet extends StatefulWidget {
  final AuthController authController;
  final String categorySlugId;
  final String categoryName;

  const _BusinessSubCategoryBottomSheet({
    required this.authController,
    required this.categorySlugId,
    required this.categoryName,
  });

  @override
  State<_BusinessSubCategoryBottomSheet> createState() =>
      _BusinessSubCategoryBottomSheetState();
}

class _BusinessSubCategoryBottomSheetState
    extends State<_BusinessSubCategoryBottomSheet> {
  SubCategories? _selectedSubCat;

  @override
  void initState() {
    super.initState();
    widget.authController
        .fetchBusinessSubCategories(categorySlugId: widget.categorySlugId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(SizeConfig.size16),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: SizeConfig.size8),
              Container(
                width: SizeConfig.size40,
                height: SizeConfig.size4,
                decoration: BoxDecoration(
                  color: AppColors.greyE5,
                  borderRadius: BorderRadius.circular(SizeConfig.size4),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.categoryName.replaceAll('\n', ' '),
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.size16,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(SizeConfig.size20),
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size4),
                        child: Icon(
                          Icons.close,
                          size: SizeConfig.size20,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.greyE5),
              Expanded(
                child: Obx(() {
                  if (widget
                      .authController.isBusinessSubCategoriesLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (widget.authController.subCategoryErrorMessage.value !=
                      null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size20),
                        child: CustomText(
                          widget.authController.subCategoryErrorMessage.value!,
                          color: AppColors.red,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final subs = widget.authController.businessSubCategoriesList;
                  if (subs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.size20),
                        child: CustomText(
                          AppStrings.accountTypeNoSubCategory,
                          fontSize: SizeConfig.medium,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
                    itemCount: subs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.greyE5),
                    itemBuilder: (context, index) {
                      final item = subs[index];
                      final isSelected = _selectedSubCat?.sId == item.sId;
                      return ListTile(
                        dense: true,
                        title: CustomText(
                          item.name ?? AppStrings.unknown,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: SizeConfig.size15,
                          color: AppColors.mainTextColor,
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: AppColors.primaryColor,
                                size: SizeConfig.size22)
                            : null,
                        onTap: () => setState(() => _selectedSubCat = item),
                      );
                    },
                  );
                }),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size20,
                    vertical: SizeConfig.size12,
                  ),
                  child: Obx(() {
                    final subs =
                        widget.authController.businessSubCategoriesList;
                    final loading = widget
                        .authController.isBusinessSubCategoriesLoading.value;
                    final canConfirm =
                        !loading && (subs.isEmpty || _selectedSubCat != null);
                    return CustomBtn(
                      radius: SizeConfig.size30,
                      isValidate: canConfirm,
                      bgColor: canConfirm
                          ? AppColors.primaryColor
                          : AppColors.whiteF3,
                      textColor:
                          canConfirm ? AppColors.white : AppColors.grey9B,
                      title: AppStrings.done,
                      onTap: canConfirm
                          ? () => Navigator.of(context)
                              .pop(_SubCategoryPickResult(_selectedSubCat))
                          : null,
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
