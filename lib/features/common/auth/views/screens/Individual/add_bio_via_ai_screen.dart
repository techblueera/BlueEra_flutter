import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/promo_code_dialog.dart';
import 'package:BlueEra/widgets/referral_applied_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBioViaAiScreen extends StatefulWidget {
  final String profession;
  final String? designation;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;

  const AddBioViaAiScreen({
    super.key,
    required this.profession,
    required this.designation,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay});

  @override
  State<AddBioViaAiScreen> createState() => _AddBioViaAiScreenState();
}

class _AddBioViaAiScreenState extends State<AddBioViaAiScreen> {
  final aiController = Get.put(AiSuggestionController());
  final ViewPersonalDetailsController viewPersonalDetailsController =
        Get.find<ViewPersonalDetailsController>();
  final personalCreateProfileController =
        Get.put(PersonalCreateProfileController());
  final TextEditingController bioController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isFormValid = false;
  late LanguageListController langController;

  @override
  void initState() {
    langController = Get.find<LanguageListController>();

    // Apply a deeplink-captured referral code if one is waiting in
    // prefs (silent path — no dialog), otherwise fall through to the
    // manual promo-code dialog. AI bio generation runs last either
    // way so its inline loader can't compete with the modal.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _applyDeferredReferralOrPrompt();
      if (!mounted) return;
      await apiCalling();
    });
    super.initState();
  }

  /// Deeplink-first referral attribution. If `_handleDeepLink` saved
  /// a code (verified BDM shared a link that this user clicked before
  /// signup), apply it silently and skip the dialog. Otherwise show
  /// the manual promo-code prompt so the user can still type a code.
  Future<void> _applyDeferredReferralOrPrompt() async {
    final saved = await SharedPreferenceUtils.getDeferredReferralCode();
    if (saved != null && saved.isNotEmpty) {
      await personalCreateProfileController.updateUserProfileDetails(
        params: {ApiKeys.referred_by_code: saved},
        isFromProfileOnly: true,
        showProgress: false,
      );
      // Consume-once: prevent a stale code from being re-applied if
      // the user creates a second profile on the same device.
      await SharedPreferenceUtils.clearDeferredReferralCode();
      // Acknowledge it so the user knows they were referred (they
      // installed via a referral link) rather than applying silently.
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReferralAppliedDialog(code: saved),
      );
      return;
    }
    if (!mounted) return;
    await _showReferralDialog();
  }

  /// Manual fallback — shown only when no deeplink-captured code is
  /// available. If the user submits a code, patch it onto their
  /// profile via `updateUserProfileDetails`.
  Future<void> _showReferralDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PromoCodeDialog(
        onBtnPressed: (code) async {
          Navigator.of(ctx).pop();
          if (code.isNotEmpty) {
            await personalCreateProfileController.updateUserProfileDetails(
              params: {ApiKeys.referred_by_code: code},
              isFromProfileOnly: true,
              showProgress: false,
            );
          }
        },
      ),
    );
  }
  apiCalling()async
  {
    await aiController.fetchSuggestions(
        bodyRequest: {
          ApiKeys.profession: widget.profession,
          ApiKeys.designation: widget.designation,
          ApiKeys.date_of_birth_Obj: {
            ApiKeys.year: widget.selectedYear,
            ApiKeys.month: widget.selectedMonth,
            ApiKeys.date: widget.selectedDay
          },
          ApiKeys.gender: viewPersonalDetailsController.personalProfileDetails.value.user?.gender
        },
        apiType: "bio",
        targetController: bioController,
        onSaved: (){
          validateForm();
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: CommonBackAppBar(
       title: AppStrings.personalDetails.tr,
     ),
      body: CustomFormCard(
        margin: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size15,
        ),
        padding: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    langController.tr(AppStrings.aboutMeBio),
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                 SizedBox(width: SizeConfig.size8),
                 InkWell(
                    onTap: () async {
                      await aiController.fetchSuggestions(
                        bodyRequest: {
                          ApiKeys.profession: widget.profession,
                          ApiKeys.designation: widget.designation,
                          ApiKeys.date_of_birth_Obj: {
                            ApiKeys.year: widget.selectedYear,
                            ApiKeys.month: widget.selectedMonth,
                            ApiKeys.date: widget.selectedDay
                          },
                          ApiKeys.gender: viewPersonalDetailsController.personalProfileDetails.value.user?.gender
                        },
                        apiType: "bio",
                        targetController: bioController,
                        onSaved: (){
                          validateForm();
                        }
                      );
                    },
                    child: Obx(()=> aiController.isLoading.value ?
                     SizedBox(
                       height: 25,
                       width: 25,
                       child: CircularProgressIndicator(
                         strokeWidth: 2.0,
                       ),
                     )
                    : LocalAssets(
                      height: 25,
                      width: 25,
                      imagePath: AppIconAssets.ai_generative,
                      imgColor: AppColors.primaryColor,
                    )),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.paddingXSL),
              CommonTextField(
                maxLength: 900,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.pleaseEnterBio.tr;
                  } else if (value.trim().length < 50) {
                    return AppStrings.bioMinLength.tr;
                  } else if (value.trim().length > 900) {
                    return AppStrings.bioMaxLength.tr;
                  }
                  return null;
                },
                hintText: "${AppStrings.writeYour.tr} ...",
                textEditController: bioController,
                maxLine: 5,
                isCounterVisible: true,
                onChange: (value)=> validateForm(),
              ),
              SizedBox(height: SizeConfig.paddingL),
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      radius: 10,
                      onTap: () {
                        Get.until((route) =>
                                 route.settings.name == RouteHelper.getBottomNavigationBarScreenRoute());
                      },
                      title: AppStrings.skip,
                      bgColor: Colors.transparent,
                      textColor: AppColors.primaryColor,
                      borderColor: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(
                    width: SizeConfig.size10,
                  ),
                  Expanded(
                    child: Obx(() {
                      final loading = personalCreateProfileController
                          .updateBtnLoading.value;
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
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
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
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      ),
    );
  }

  void validateForm() {
    isFormValid = bioController.text.trim().isNotEmpty;
    setState(() {});
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await personalCreateProfileController.updateUserProfileDetails(
      showProgress: false,
      params: {
        ApiKeys.bio: bioController.text.trim(),
      },
    );

    final bottomNavRoute = RouteHelper.getBottomNavigationBarScreenRoute();
    final landingIndex = widget.profession == SELF_EMPLOYED ? 2 : 1;

    // The bottom-nav is only already on the stack when the user came through
    // as a guest — splash makes it the root for anyone already logged in. A
    // first-time signup starts at the login screen instead, so nothing ever
    // built the bottom-nav and its controller was never registered: `Get.find`
    // threw here, and popping "until" a route that isn't on the stack would
    // have stranded the brand-new user back on login. Build it as the new root
    // in that case, which is what splash does for every other entry path.
    if (!Get.isRegistered<BottomBarController>()) {
      Get.offAllNamed(
        bottomNavRoute,
        arguments: {ApiKeys.initialIndex: landingIndex},
      );
      return;
    }

    // Pop everything back down to the BottomNavigation root. `route.isFirst`
    // terminates the walk if the named route somehow isn't on the stack, so a
    // mismatch can't pop the navigator empty.
    Get.until((route) =>
        route.settings.name == bottomNavRoute || route.isFirst);

    if (widget.profession == SELF_EMPLOYED) {
      Get.find<BottomBarController>().currentIndex.value = landingIndex;
    }
  }
}
