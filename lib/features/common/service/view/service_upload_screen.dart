import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceUploadScreen extends StatefulWidget {
  final ProviderType providerType;
  final String? channelId;

  /// Opt-in flag that swaps the name / short-description hints to
  /// category-specific copy (Banking, IT, Consulting, Beauty, Home
  /// Services, Vehicle Service, etc.) when the current business's
  /// [businessCategoryGlobal] matches one of the service-eligible
  /// categories catalogued in `business_enquiry_sheet.dart`. Off by
  /// default so every existing caller (channel screen, deep-link routes,
  /// [RentalServiceUploadScreen], etc.) keeps the generic hint it
  /// always had — only the caller that explicitly passes
  /// `enableBankingHints: true` gets the category-aware copy. Kept
  /// as `enableBankingHints` to avoid churning the four opt-in call
  /// sites (Others tab, Automotive tab, business-service-list); the
  /// semantics now cover every category, not just Banking.
  final bool enableBankingHints;

  ServiceUploadScreen({
    Key? key,
    required this.providerType,
    this.channelId,
    this.enableBankingHints = false,
  }) : super(key: key);

  @override
  State<ServiceUploadScreen> createState() => _ServiceUploadScreenState();
}

class _ServiceUploadScreenState extends State<ServiceUploadScreen> {
  final ServiceController controller = Get.put(ServiceController());
  // final viewBusinessDetailsController =
  //     Get.find<ViewBusinessDetailsController>();

  static const _accent = LinearGradient(
    colors: [AppColors.blue5CAF, AppColors.primaryColor],
  );

  bool get _isIndividual => accountTypeGlobal == AppConstants.individual;

  /// Normalises [businessCategoryGlobal] so both the slug form
  /// (`IT_DIGITAL_SERVICES`) and legacy display strings ("IT Digital
  /// Services") match the same switch key. Uppercased + spaces →
  /// underscores gets both formats onto the canonical slug shape.
  String get _categoryKey =>
      businessCategoryGlobal.trim().toUpperCase().replaceAll(' ', '_');

  /// Category-specific hints for the service-name and short-description
  /// fields. Returns `null` when the caller hasn't opted in via
  /// [ServiceUploadScreen.enableBankingHints] (the opt-in gate is what
  /// protects unrelated callers of this screen), or when the current
  /// category isn't one we have bespoke copy for — the fields then fall
  /// back to the generic hints from `AppStrings`.
  ///
  /// Slug list mirrors the eight Find-Services + four Finance + three
  /// Automotive categories catalogued in
  /// `business_enquiry_sheet.dart` (see the doc header at line 79) so
  /// every business type the "Others / Automotive / Finance" flows can
  /// register as gets a first-run example that reads like a real listing
  /// instead of the generic "Enter service name" placeholder.
  ({String nameHint, String descHint})? get _categoryHints {
    if (!widget.enableBankingHints) return null;
    if (_isIndividual) return null;
    switch (_categoryKey) {
      // ── Finance ──
      case 'BANKING_SECTOR':
      case 'BANKING':
        return (
          nameHint: 'e.g., Savings Account Opening',
          descHint:
              'e.g., Zero-balance savings account with debit card, net banking & instant UPI',
        );
      case 'LOANS_SECTOR':
        return (
          nameHint: 'e.g., Personal Loan',
          descHint:
              'e.g., Quick disbursal, minimal documentation, flexible EMI options',
        );
      case 'INSURANCE_SECTOR':
        return (
          nameHint: 'e.g., Term Life Insurance',
          descHint:
              'e.g., Comprehensive coverage with flexible premium options and quick claim settlement',
        );
      case 'FINANCIAL_SERVICES':
        return (
          nameHint: 'e.g., Financial Planning',
          descHint:
              'e.g., Expert advice on investments, tax planning & wealth management',
        );
      // ── Find Services ──
      case 'CONSULTING_BUSINESS_SERVICES':
        return (
          nameHint: 'e.g., Business Strategy Consultation',
          descHint:
              'e.g., Expert guidance on growth, operations & market expansion — 1-hour session with follow-up notes',
        );
      case 'BEAUTY_FITNESS_PERSONAL_CARE':
        return (
          nameHint: 'e.g., Bridal Makeup',
          descHint:
              'e.g., Professional makeup with skincare prep, hairstyling & pre-shoot trial session',
        );
      case 'REPAIR_ESSENTIAL_SERVICES':
        return (
          nameHint: 'e.g., AC Repair & Service',
          descHint:
              'e.g., Trained technicians, genuine spare parts & 30-day service warranty',
        );
      case 'HOME_SERVICES_CONTRACTORS':
        return (
          nameHint: 'e.g., Home Painting',
          descHint:
              'e.g., Interior & exterior painting with premium paints, surface prep and post-work clean-up',
        );
      case 'IT_DIGITAL_SERVICES':
        return (
          nameHint: 'e.g., Website Development',
          descHint:
              'e.g., Custom-designed responsive websites with SEO setup & 3 months of free support',
        );
      case 'MEDIA_NEWS_CREATIVE':
        return (
          nameHint: 'e.g., Wedding Photography',
          descHint:
              'e.g., Full-day coverage with drone shots, candid photos & edited album delivered in 2 weeks',
        );
      case 'TRAVEL_HOSPITALITY':
        return (
          nameHint: 'e.g., Weekend Getaway Package',
          descHint:
              'e.g., 3-day trip with stay, meals, sightseeing & local transport included',
        );
      case 'REAL_ESTATE_PROPERTY':
        return (
          nameHint: 'e.g., Property Listing',
          descHint:
              'e.g., Verified property with photos, virtual tour & documentation support',
        );
      // ── Automotive ──
      case 'VEHICLE_SERVICE':
        return (
          nameHint: 'e.g., Car Service & Repair',
          descHint:
              'e.g., Complete service with genuine parts, warranty & doorstep pickup and drop',
        );
      case 'VEHICLE_SUPPORT':
        return (
          nameHint: 'e.g., 24x7 Roadside Assistance',
          descHint:
              'e.g., On-call breakdown support, towing & on-site minor repair across the city',
        );
      case 'TRANSPORT_LOGISTICS_PARKING':
        return (
          nameHint: 'e.g., Intercity Cargo Transport',
          descHint:
              'e.g., GPS-tracked shipments, insured cargo & timely doorstep delivery',
        );
      default:
        return null;
    }
  }

  String get _serviceNameHint =>
      _categoryHints?.nameHint ?? AppStrings.hintServiceName;

  String get _shortDescriptionHint =>
      _categoryHints?.descHint ?? AppStrings.hintShortDescription;

  @override
  void initState() {
    // viewBusinessDetailsController.getAllCategories();
    controller.providerType = widget.providerType;
    if (widget.channelId != null) controller.channelId = widget.channelId;
    super.initState();
  }

  @override
  void dispose() {
    deleteIfRegistered<ServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(title: AppStrings.service),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Obx(
          () => AbsorbPointer(
            absorbing: controller.isGenerateAiServiceLoading.value,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size12,
                SizeConfig.size16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: SizeConfig.size12),
                  _buildContextCard(),
                  SizedBox(height: SizeConfig.size12),
                  _buildMainCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HERO — gradient banner introducing the AI flow.
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size14, vertical: SizeConfig.size12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _accent,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -22,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 19),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      'Add your service in minutes',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      'Fill a few details and let AI craft your listing',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONTEXT CARD — "heads up, we'll use your existing profile bits".
  // ─────────────────────────────────────────────────────────────
  Widget _buildContextCard() {
    const amber = Color(0xFFB45309);
    final title = _isIndividual
        ? AppStrings.yourProfessionDesignation
        : AppStrings.yourCategorySubcategory;
    final note = _isIndividual
        ? AppStrings.kindlyAddServicesProfession
        : AppStrings.kindlyAddServicesCategory;
    // Only nudge the user when the profile data we rely on is actually
    // missing — no point warning when profession/designation (or category/
    // subcategory) are already set.
    final showWarning = _isIndividual
        ? (userProfessionGlobal.trim().isEmpty ||
            userDesignationGlobal.trim().isEmpty)
        : (businessCategoryGlobal.trim().isEmpty ||
            businessSubCategoryGlobal.trim().isEmpty);

    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6DDB0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 17, color: amber),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C4A06),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          if (_isIndividual) ...[
            _kvRow(AppStrings.profession, userProfessionGlobal),
            _kvRow(AppStrings.workType, userDesignationGlobal),
          ] else ...[
            _kvRow(AppStrings.category.tr, businessCategoryGlobal),
            _kvRow(AppStrings.subcategory.tr, businessSubCategoryGlobal),
          ],
          if (showWarning) ...[
            SizedBox(height: SizeConfig.size6),
            Container(height: 1, color: const Color(0xFFF1DFC0)),
            SizedBox(height: SizeConfig.size8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.red00),
                SizedBox(width: SizeConfig.size6),
                Expanded(
                  child: CustomText(
                    note,
                    color: AppColors.red00,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9A7B45),
            ),
          ),
          Expanded(
            child: CustomText(
              value.trim().isEmpty ? '—' : value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4A14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN CARD — photo + category + name + description.
  // ─────────────────────────────────────────────────────────────
  Widget _buildMainCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12001120),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.image_outlined, AppStrings.uploadImages),
          SizedBox(height: SizeConfig.size10),
          _buildImageTile(context),
          SizedBox(height: SizeConfig.size20),
          _sectionHeader(
              Icons.design_services_outlined, AppStrings.serviceName),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            title: '',
            textEditController: controller.serviceNameController,
            hintText: _serviceNameHint,
            onChange: (value) => controller.serviceName.value = value,
          ),
          SizedBox(height: SizeConfig.size20),
          if (_isIndividual) ...[
            _sectionHeader(Icons.category_outlined, AppStrings.category.tr),
            SizedBox(height: SizeConfig.size10),
            _buildCategoryGrid(),
            SizedBox(height: SizeConfig.size20),
          ],
          _sectionHeader(Icons.notes_outlined, AppStrings.shortDescription,
              optional: true),
          SizedBox(height: SizeConfig.size10),
          CommonTextField(
            title: '',
            textEditController: controller.serviceShortDescriptionController,
            hintText: _shortDescriptionHint,
            maxLine: 3,
            validator: validateServiceDescription,
            onChange: (value) => controller.shortDescriptionName.value = value,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, {bool optional = false}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: CustomText(
            title,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ),
        if (optional) ...[
          SizedBox(width: SizeConfig.size8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.greyE5.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              'Optional',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Category grid (static options) — photo + label cards, single-select.
  Widget _buildCategoryGrid() {
    return Obx(() {
      final selectedTagId = controller.selectedServiceCategory.value?.tagId;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: ServiceController.serviceCategoryOptions.length,
        itemBuilder: (_, i) {
          final cat = ServiceController.serviceCategoryOptions[i];
          final isSelected = selectedTagId == cat.tagId;
          return CommonServiceCard<ServiceCategoryOption>(
            service: cat,
            getName: (item) => item.name,
            getIcon: (item) => item.image,
            isSelected: isSelected,
            onTap: (item) {
              controller.selectedServiceCategory.value =
                  isSelected ? null : item;
            },
          );
        },
      );
    });
  }

  // ─── Image: dashed drop tile when empty, full-width preview once picked ───
  Widget _buildImageTile(BuildContext context) {
    return Obx(() {
      final file = controller.selectedImage.value;
      if (file == null) {
        return GestureDetector(
          onTap: () => _pickImage(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 158,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppImageAssets.homeServicesBanner,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryColor.withValues(alpha: 0.06)),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.32)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined,
                              color: Colors.white, size: 22),
                        ),
                        SizedBox(height: SizeConfig.size10),
                        CustomText(
                          'Add a service photo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          'Tap to upload from your device',
                          fontSize: SizeConfig.small,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              height: 158,
              width: double.infinity,
              color: AppColors.whiteFE,
              child: Image.file(file,
                  width: double.infinity, height: 158, fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _pickImage(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      CustomText('Change',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    final String? selected = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.selectPhoto.tr,
    );
    if ((selected?.isNotEmpty ?? false) && selected != null) {
      controller.selectedImage.value = File(selected);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // STICKY BOTTOM BAR — gradient Generate CTA (disabled until valid).
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.greyE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            SizeConfig.size12,
            SizeConfig.size12,
            SizeConfig.size12,
          ),
          child: Obx(() {
            final loading = controller.isGenerateAiServiceLoading.value;
            // isValidate/isPersonalServiceValidate read the reactive name /
            // image / category fields, so the button re-evaluates live.
            final valid =
                _isIndividual ? isPersonalServiceValidate() : isValidate();
            final enabled = valid && !loading;
            return Opacity(
              opacity: enabled ? 1 : 0.5,
              child: GestureDetector(
                onTap: enabled ? _onGenerate : null,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.32),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 19),
                              SizedBox(width: SizeConfig.size8),
                              CustomText(
                                AppStrings.generate,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onGenerate() async {
    if (_isIndividual) {
      if (!isPersonalServiceValidate()) return;
      controller.serviceSubType = 'homeService';
      controller.category =
          controller.selectedServiceCategory.value?.tagId ?? '';
      await controller.generateServiceAiController(
        serviceDetailsReq: {
          ApiKeys.service_name: controller.serviceName.value,
          ApiKeys.category: controller.category,
          if (controller.shortDescriptionName.value.isNotEmpty)
            ApiKeys.short_description: controller.shortDescriptionName.value,
        },
      );
    } else {
      if (!isValidate()) return;
      controller.category = businessCategoryGlobal;
      await controller.generateServiceAiController(
        serviceDetailsReq: {
          ApiKeys.service_name: controller.serviceName.value,
          if (isBusiness()) ApiKeys.category: businessCategoryGlobal,
          if (isBusiness()) ApiKeys.sub_category: businessSubCategoryGlobal,
          if (controller.shortDescriptionName.value.isNotEmpty)
            ApiKeys.short_description: controller.shortDescriptionName.value,
        },
      );
    }
  }

  isValidate() {
    return (controller.selectedImage.value != null &&
        controller.serviceName.value.isNotEmpty);
  }

  isPersonalServiceValidate() {
    return (controller.selectedImage.value != null &&
        controller.serviceName.value.isNotEmpty &&
        controller.selectedServiceCategory.value != null);
  }

  // Short description is optional — empty is allowed; only enforce a sensible
  // minimum length once the user actually types something.
  String? validateServiceDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 15) {
      return AppStrings.serviceDescriptionMinLength.tr;
    }
    return null;
  }
}
