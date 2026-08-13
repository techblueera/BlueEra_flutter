import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/business_description/business_description_controller.dart';
import 'package:BlueEra/features/business/business_description/model/business_description_suggestion_model.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Final step of business signup — the business description, moved off step
/// three so it gets a screen of its own. Offers the ready-written
/// descriptions for the business's category
/// (`GET business/description-suggestions`, see
/// docs/FLUTTER_BUSINESS_DESCRIPTION_SUGGESTIONS_GUIDE.md) alongside the
/// existing AI generator. Neither is required — the field stays editable by
/// hand, and the step can be skipped.
class CreateBusinessAccountNewStepFour extends StatefulWidget {
  final String? city;

  const CreateBusinessAccountNewStepFour({super.key, this.city});

  @override
  State<CreateBusinessAccountNewStepFour> createState() =>
      _CreateBusinessAccountNewStepFourState();
}

class _CreateBusinessAccountNewStepFourState
    extends State<CreateBusinessAccountNewStepFour> {
  final descriptionController = getOrPut(() => BusinessDescriptionController());
  final viewBusinessDetailsController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  /// The shared controller the AI suggestion dialog writes into, so both entry
  /// points land in the same field.
  TextEditingController get _descriptionTextController =>
      viewBusinessDetailsController.listingDescriptionController.value;

  bool isFormValid = false;
  int _descriptionLength = 0;
  int? _selectedSuggestionIndex;

  @override
  void initState() {
    super.initState();

    // Seed the field from whatever the profile already carries (re-entering
    // the step, or an AI pick made earlier).
    if (_descriptionTextController.text.trim().isEmpty &&
        viewBusinessDetailsController.businessDescription.value
            .trim()
            .isNotEmpty) {
      _descriptionTextController.text =
          viewBusinessDetailsController.businessDescription.value;
    }

    _descriptionTextController.addListener(_onDescriptionChanged);
    final seeded = _descriptionTextController.text;
    viewBusinessDetailsController.businessDescription.value = seeded;
    _descriptionLength = seeded.length;
    isFormValid = seeded.trim().isNotEmpty;

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadCategorySuggestions());
  }

  @override
  void dispose() {
    _descriptionTextController.removeListener(_onDescriptionChanged);
    super.dispose();
  }

  /// The description Rx is also refreshed from the server by the profile
  /// fetch that follows every `updateBusinessDetails`, so the field's text —
  /// not the Rx — is the source of truth on this screen. Keep the Rx in step
  /// with it for the rest of the app.
  void _onDescriptionChanged() {
    final text = _descriptionTextController.text;
    viewBusinessDetailsController.businessDescription.value = text;

    final length = text.length;
    final valid = text.trim().isNotEmpty;
    if (!mounted || (length == _descriptionLength && valid == isFormValid)) {
      return;
    }
    setState(() {
      _descriptionLength = length;
      isFormValid = valid;
    });
  }

  /// Category identifier for the suggestions call. `category_Of_Business` is
  /// the category **tag_id** — the preferred identifier — with the category
  /// `_id`/name and the signup selection as fallbacks.
  String get _categoryIdentifier {
    final data = viewBusinessDetailsController.businessProfileDetails.value?.data;
    final candidates = <String?>[
      data?.categoryOfBusiness,
      data?.categoryDetails?.id,
      data?.categoryDetails?.name,
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().selectedCategorySlugId
          : null,
    ];
    return candidates.firstWhere((e) => (e ?? '').trim().isNotEmpty,
            orElse: () => '') ??
        '';
  }

  /// Subcategory `_id` where the business has one. A bare subcategory *name*
  /// is ambiguous across categories, so an id is preferred — but the name is
  /// safe here because it always travels with its category.
  String get _subCategoryIdentifier {
    final data = viewBusinessDetailsController.businessProfileDetails.value?.data;
    final candidates = <String?>[
      data?.subCategoryDetails?.id,
      data?.subCategoryOfBusiness,
      data?.subCategoryDetails?.name,
      Get.isRegistered<AuthController>()
          ? Get.find<AuthController>().selectedSubCategoryData?.sId
          : null,
    ];
    return candidates.firstWhere((e) => (e ?? '').trim().isNotEmpty,
            orElse: () => '') ??
        '';
  }

  /// Fills `{business_name}` in the suggestions. Falls back to the name typed
  /// in step one, so a profile fetch still in flight can't leave the raw
  /// placeholder token on screen.
  String get _businessName {
    final fromProfile = viewBusinessDetailsController
            .businessProfileDetails.value?.data?.businessName ??
        '';
    if (fromProfile.trim().isNotEmpty) return fromProfile;
    if (!Get.isRegistered<AuthController>()) return '';
    final authController = Get.find<AuthController>();
    return authController.businessName.value.trim().isNotEmpty
        ? authController.businessName.value
        : authController.businessNameTextController.text;
  }

  Future<void> _loadCategorySuggestions() async {
    await descriptionController.fetchCategorySuggestions(
      category: _categoryIdentifier,
      subCategory: _subCategoryIdentifier,
      businessName: _businessName,
    );
  }

  /// The existing AI generator — opens its own selection dialog and writes
  /// the pick into the same field.
  Future<void> _generateAiDescription() async {
    final data = viewBusinessDetailsController.businessProfileDetails.value?.data;
    await descriptionController.generateDescriptions(
      onSaved: _onDescriptionChanged,
      bodyRequest: {
        ApiKeys.business_name: data?.businessName,
        ApiKeys.category: data?.categoryDetails?.name,
        ApiKeys.sub_category: data?.subCategoryDetails?.name,
        ApiKeys.city: widget.city,
      },
    );
    if (!mounted) return;
    setState(() => _selectedSuggestionIndex = null);
    _onDescriptionChanged();
  }

  void _applySuggestion(int index, DescriptionSuggestion suggestion) {
    // The field caps at 400 characters, so keep the sentences that fit.
    _descriptionTextController.text =
        suggestion.fittedTo(AppConstants.inputCharterLimit400);
    setState(() => _selectedSuggestionIndex = index);
    _onDescriptionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonBackAppBar(
          isLeading: true, title: AppStrings.businessDescriptionTitle),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      AppStrings.shortBusinessDescription,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                /*    Obx(() => !descriptionController.isLoading.value
                        ? InkWell(
                            onTap: _generateAiDescription,
                            child: LocalAssets(
                              height: 25,
                              width: 25,
                              imgColor: AppColors.primaryColor,
                              imagePath: AppIconAssets.ai_generative,
                            ))
                        : SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )),*/
                  ],
                ),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  AppStrings.businessDescriptionSubtitle,
                  fontSize: SizeConfig.small,
                  color: AppColors.grey9B,
                ),
                SizedBox(height: SizeConfig.paddingXSL),
                CommonTextField(
                  validator: null,
                  borderWidth: 0,
                  borderColor: Colors.transparent,
                  hintText: AppStrings.businessDescriptionExample,
                  textEditController: _descriptionTextController,
                  maxLine: 5,
                  isValidate: false,
                  maxLength: AppConstants.inputCharterLimit400,
                  onChange: (val) {
                    // Typing over a picked suggestion drops the selection tick.
                    if (_selectedSuggestionIndex != null) {
                      setState(() => _selectedSuggestionIndex = null);
                    }
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      AppConstants.inputCharterLimit400,
                    ),
                    NoLeadingSpaceFormatter(),
                    NoConsecutiveSpacesFormatter(),
                  ],
                ),
                SizedBox(height: SizeConfig.size10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: CustomText(
                    "$_descriptionLength/${AppConstants.inputCharterLimit400}",
                    color: AppColors.grey9B,
                    fontSize: SizeConfig.small,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                _suggestionsSection(),
                SizedBox(height: SizeConfig.size28),
                Row(
                  children: [
                    Expanded(
                      child: CustomBtn(
                        radius: 10,
                        onTap: _goToHome,
                        title: AppStrings.skip,
                        bgColor: Colors.transparent,
                        textColor: AppColors.primaryColor,
                        borderColor: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size10),
                    Expanded(
                      child: Obx(() {
                        final loading = viewBusinessDetailsController
                            .isUpdateBusinessDetailsLoading.value;
                        final canSubmit = isFormValid && !loading;
                        return SizedBox(
                          height: SizeConfig.size44,
                          child: ElevatedButton.icon(
                            onPressed: canSubmit ? _onSubmit : null,
                            icon: loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            label: Text(
                              loading
                                  ? '${AppStrings.submit.tr}…'
                                  : AppStrings.submit.tr,
                              style: TextStyle(
                                fontFamily: AppConstants.OpenSans,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              disabledBackgroundColor: loading
                                  ? AppColors.primaryColor
                                      .withValues(alpha: 0.5)
                                  : AppColors.greyB4,
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size12,
                                horizontal: SizeConfig.size16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionsSection() {
    return Obx(() {
      final loading = descriptionController.isCategorySuggestionsLoading.value;
      final suggestions = descriptionController.categorySuggestions;
      final message = descriptionController.categorySuggestionsMessage.value;

      if (loading) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          ),
        );
      }

      // Nothing to offer — the field stays editable by hand, so this is only
      // ever a note, never a blocker.
      if (suggestions.isEmpty) {
        if (message.isEmpty) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: CustomText(
                message,
                fontSize: SizeConfig.small,
                color: AppColors.grey9B,
              ),
            ),
            TextButton(
              onPressed: _loadCategorySuggestions,
              child: CustomText(
                AppStrings.retryLoadSuggestions,
                fontSize: SizeConfig.small,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.suggestedDescriptions,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              InkWell(
                onTap: _loadCategorySuggestions,
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(
            AppStrings.tapToUseSuggestion,
            fontSize: SizeConfig.small,
            color: AppColors.grey9B,
          ),
          SizedBox(height: SizeConfig.size10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
            itemBuilder: (_, index) {
              final suggestion = suggestions[index];
              final isSelected = _selectedSuggestionIndex == index;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _applySuggestion(index, suggestion),
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.greyB4,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 20,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.grey9B,
                      ),
                      SizedBox(width: SizeConfig.size10),
                      Expanded(
                        child: CustomText(
                          suggestion.asSpacedParagraphs,
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  void _goToHome() {
    Get.offAllNamed(
      RouteHelper.getBottomNavigationBarScreenRoute(),
      // A new business lands on Discover (1) right after signup, same as an
      // individual — the marketplace, not its own empty dashboard.
      arguments: {ApiKeys.initialIndex: 1},
    );
  }

  Future<void> _onSubmit() async {
    final description = _descriptionTextController.text.trim();
    if (description.isEmpty) return;

    await viewBusinessDetailsController.updateBusinessDetails(
      <String, dynamic>{
        ApiKeys.businessId: businessId,
        ApiKeys.business_description: description,
      },
      showProgress: false,
    );

    _goToHome();
  }
}
