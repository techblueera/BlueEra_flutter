import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_exit_handler.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CompleteGuestProfileScreen extends StatefulWidget {
  const CompleteGuestProfileScreen({super.key});

  @override
  State<CompleteGuestProfileScreen> createState() =>
      _CompleteGuestProfileScreenState();
}

class _CompleteGuestProfileScreenState
    extends State<CompleteGuestProfileScreen> {
  final _authController = getOrPut(() => AuthController());
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final RxnString _nameError = RxnString();
  final RxBool _isNameValid = false.obs;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_syncNameValidity);
  }

  void _syncNameValidity() {
    _isNameValid.value = _nameController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncNameValidity);
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    final validationError = ValidationMethod.validateName(name);
    if (validationError != null) {
      _nameError.value = validationError;
      _nameFocus.requestFocus();
      HapticFeedback.lightImpact();
      return;
    }
    _nameError.value = null;
    FocusScope.of(context).unfocus();
    await _authController.createGuestAccountUserController(
      reqData: {
        ApiKeys.contact_no: _authController.mobileNumberEditController.text,
        ApiKeys.account_type: AppConstants.guest,
        ApiKeys.name: name,
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        GuestExitHandler.handleBack(context);
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: AppStrings.guestProfile.tr,
          isShadowShow: false,
          onBackTap: () => GuestExitHandler.handleBack(context),
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size8,
                  SizeConfig.size16,
                  SizeConfig.size8,
                  SizeConfig.size20,
                ),
                child: CustomFormCard(
                  isBoxShadowAvail: true,
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size20,
                    SizeConfig.size20,
                    SizeConfig.size20,
                    SizeConfig.size24,
                  ),
                  // Name is the only thing a guest is asked for — the profile
                  // picture used to sit above it (optional) and was dropped so
                  // the screen is a single field between the guest and the app.
                  child: _nameSection(),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _bottomActions(),
      ),
    );
  }

  Widget _heading(String title) {
    return CustomText(
      title,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
  }

  Widget _nameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _heading(AppStrings.fullName.tr),
            SizedBox(width: SizeConfig.size4),
            CustomText(
              '*',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: _nameController,
          focusNode: _nameFocus,
          inputLength: AppConstants.inputCharterLimit30,
          keyBoardType: TextInputType.text,
          regularExpression: RegularExpressionUtils.alphabetOnlySpacePattern,
          hintText: "Bhagavan",
          autoFillType: AutoFillType.name,
          maxLength: 15,
          isValidate: false,
          textInputAction: TextInputAction.done,
          onChange: (_) {
            if (_nameError.value != null) _nameError.value = null;
          },
          onDone: (_) => FocusScope.of(context).unfocus(),
        ),
        Obx(() {
          final err = _nameError.value;
          return AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: SizeConfig.size16,
                          color: AppColors.red00,
                        ),
                        SizedBox(width: SizeConfig.size4),
                        Expanded(
                          child: CustomText(
                            err,
                            fontSize: SizeConfig.small,
                            color: AppColors.red00,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        }),
      ],
    );
  }

  Widget _bottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size20,
        SizeConfig.size12,
        SizeConfig.size20,
        SizeConfig.size16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final loading = _authController
                      .createGuestProfileResponse.value.status ==
                  Status.LOADING;
              final canSubmit = _isNameValid.value && !loading;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: SizeConfig.size44,
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? _onContinue : null,
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
                          ? '${AppStrings.continueText.tr}…'
                          : AppStrings.continueText.tr,
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
                      // Loading keeps the light-blue tint so the spinner
                      // still reads as "in progress"; empty-name uses a
                      // neutral grey so the button looks properly disabled.
                      disabledBackgroundColor: loading
                          ? AppColors.primaryColor.withValues(alpha: 0.5)
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
                ),
              );
            }),

            // SizedBox(height: SizeConfig.size10),
            // // Skip is intentionally a low-emphasis text link.
            // Material(
            //   color: Colors.transparent,
            //   child: InkWell(
            //     onTap: _onSkip,
            //     borderRadius: BorderRadius.circular(8),
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(
            //         horizontal: SizeConfig.size16,
            //         vertical: SizeConfig.size10,
            //       ),
            //       child: CustomText(
            //         AppStrings.skip.tr,
            //         fontSize: SizeConfig.medium,
            //         fontWeight: FontWeight.w600,
            //         color: AppColors.secondaryTextColor,
            //       ),
            //     ),
            //   ),
            // ),

          ],
        ),
      ),
    );
  }
}
