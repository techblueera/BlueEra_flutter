import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/auth/views/screens/guest_exit_handler.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  final RxString _profileImagePath = ''.obs;
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

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final path = await SelectProfilePictureDialog.showLogoDialog(
      context,
      AppStrings.editProfilePicture.tr,
      isOnlyCamera: true,
      isGallery: true,
    );
    if (path is String && path.isNotEmpty) {
      _profileImagePath.value = path;
    }
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
        if (_profileImagePath.value.isNotEmpty) ApiKeys.profile_image: _profileImagePath.value,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _photoSectionHeader(),
                      SizedBox(height: SizeConfig.size20),
                      Center(child: _profilePicker()),
                      SizedBox(height: SizeConfig.size24),
                      Divider(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.08),
                        height: 1,
                        thickness: 1,
                      ),
                      SizedBox(height: SizeConfig.size20),
                      _nameSection(),
                    ],
                  ),
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

  Widget _photoSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(
          AppStrings.profilePicture.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
        ),
        SizedBox(width: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size10,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: CustomText(
            AppStrings.optional.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _profilePicker() {
    final avatarSize = SizeConfig.size120 + SizeConfig.size20;
    final haloSize = avatarSize + SizeConfig.size40;
    final badgeSize = SizeConfig.size40 + SizeConfig.size4;
    // 45° offset on the avatar perimeter, then pulled inward by ~28% of badge
    // so half the badge sits outside the avatar's circle and half overlaps.
    final radius = avatarSize / 2;
    final angleOffset = radius * 0.7071; // cos/sin 45°
    final pullIn = badgeSize * 0.28;
    final badgeDx = angleOffset - pullIn;
    final badgeDy = angleOffset - pullIn;

    return GestureDetector(
      onTap: _pickPhoto,
      child: SizedBox(
        width: haloSize,
        height: haloSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft radial halo behind the avatar — adds depth without
            // shipping any new dependency.
            Container(
              width: haloSize,
              height: haloSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryColor.withValues(alpha: 0.10),
                    AppColors.primaryColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
            // Avatar + badge live in their own stack so the badge can be
            // positioned relative to the avatar's edge (not the halo).
            SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Obx(() {
                    final path = _profileImagePath.value;
                    final hasImage = path.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            hasImage ? AppColors.white : AppColors.whiteF3,
                        border: Border.all(
                          color: hasImage
                              ? AppColors.primaryColor
                              : AppColors.primaryColor
                                  .withValues(alpha: 0.35),
                          width: hasImage ? 2.0 : 1.4,
                        ),
                        image: hasImage
                            ? DecorationImage(
                                image: FileImage(File(path)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(
                              alpha: hasImage ? 0.18 : 0.06,
                            ),
                            blurRadius: 24,
                            spreadRadius: hasImage ? 1 : 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: hasImage
                          ? null
                          : Center(
                              child: LocalAssets(
                                imagePath: AppIconAssets.user,
                                imgColor: AppColors.primaryColor
                                    .withValues(alpha: 0.55),
                                height: SizeConfig.size60,
                                width: SizeConfig.size60,
                              ),
                            ),
                    );
                  }),
                  Positioned(
                    left: radius + badgeDx - badgeSize / 3.5,
                    top: radius + badgeDy - badgeSize / 3.5,
                    child: Obx(() {
                      final hasImage = _profileImagePath.value.isNotEmpty;
                      return Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: LocalAssets(
                            imagePath: hasImage
                                ? AppIconAssets.pen_line
                                : AppIconAssets.cameraWhiteIcon,
                            imgColor: AppColors.white,
                            height: SizeConfig.size18,
                            width: SizeConfig.size18,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          regularExpression: RegularExpressionUtils.alphabetSpacePattern,
          hintText: AppStrings.fullNameHint.tr,
          autoFillType: AutoFillType.name,
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
              final enabled = _isNameValid.value;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: enabled
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
                child: CustomBtn(
                  onTap: enabled ? _onContinue : null,
                  title: AppStrings.continueText.tr,
                  isValidate: enabled,
                  textColor: AppColors.white,
                  radius: 10,
                  height: SizeConfig.size50,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  isLoading: _authController.isCreateGuestAccountLoading.value,
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
