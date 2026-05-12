import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/ai_suggestion_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Stand-alone Bio tile shown in the Overview tab of every personal
/// dashboard (self-employed, rider, cab/transport, professional). Read
/// path is the live `User.bio` on [ViewPersonalDetailsController]; the
/// tile's Edit affordance opens a bottom sheet whose layout mirrors
/// [AddBioViaAiScreen] (label row + AI-generate spinner + textfield +
/// Save CTA) so the create-time and edit-time bio UX feels identical.
///
/// AI bio regeneration inputs (profession / designation / DOB / gender)
/// are sourced directly off the user model, so callers just drop
/// `const ProfileBioCard()` into their overview list — no per-screen
/// wiring of suggestion params.
class ProfileBioCard extends StatelessWidget {
  /// Outer margin override. Defaults match the other Overview cards'
  /// horizontal padding so the tile slots into the existing rhythm
  /// without a per-call wrapper.
  final EdgeInsetsGeometry margin;

  const ProfileBioCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    final viewCtrl = Get.find<ViewPersonalDetailsController>();
    return Container(
      margin: margin,
      child: Obx(() {
        final bio =
            viewCtrl.personalProfileDetails.value.user?.bio?.trim() ?? '';
        return _buildCard(context, bio);
      }),
    );
  }

  Widget _buildCard(BuildContext context, String bio) {
    final hasBio = bio.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — uppercase eyebrow + Add/Edit action chip on the
          // right. The chip swaps icon and label based on whether a
          // bio exists, so the affordance reads correctly in both
          // states.
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.bio.tr.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryTextColor,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              _actionChip(context, hasBio: hasBio),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          if (hasBio)
            ExpandableText(
              text: bio,
              trimLines: 3,
              isReadMoreNewLine: false,
              expandMode: ExpandMode.dialog,
              dialogTitle: AppStrings.bio.tr,
              style: TextStyle(
                color: AppColors.mainTextColor,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                fontFamily: AppConstants.OpenSans,
                height: 1.5,
              ),
            )
          else
            _placeholder(context),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context, {required bool hasBio}) {
    return InkWell(
      onTap: () => _openEditSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasBio ? Icons.edit_outlined : Icons.add_rounded,
              size: 12,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            CustomText(
              hasBio ? 'Edit' : 'Add',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return InkWell(
      onTap: () => _openEditSheet(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6E8EE), width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size6),
            Expanded(
              child: CustomText(
                'Add a short bio so visitors know your story.',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BioEditSheet(),
    );
  }
}

/// Bottom-sheet bio editor — drag handle + header + label row with the
/// inline AI-generate button + bio textfield + Update CTA. Hydrates
/// from the current `User.bio` on open, runs save through
/// [PersonalCreateProfileController.updateUserProfileDetails], and
/// uses [AiSuggestionController.fetchSuggestions] (apiType `"bio"`)
/// for the regenerate button — same machinery
/// [AddBioViaAiScreen] uses.
class _BioEditSheet extends StatefulWidget {
  const _BioEditSheet();

  @override
  State<_BioEditSheet> createState() => _BioEditSheetState();
}

class _BioEditSheetState extends State<_BioEditSheet> {
  late final TextEditingController _bioController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ViewPersonalDetailsController _viewCtrl =
      Get.find<ViewPersonalDetailsController>();
  final PersonalCreateProfileController _personalCtrl =
      Get.put(PersonalCreateProfileController());
  final AiSuggestionController _aiCtrl =
      Get.put(AiSuggestionController());

  bool _isValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial =
        _viewCtrl.personalProfileDetails.value.user?.bio?.trim() ?? '';
    _bioController = TextEditingController(text: initial);
    _isValid = initial.isNotEmpty;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _validate() {
    if (!mounted) return;
    setState(() {
      _isValid = _bioController.text.trim().isNotEmpty;
    });
  }

  Future<void> _regenerateAi() async {
    final user = _viewCtrl.personalProfileDetails.value.user;
    final dob = user?.dateOfBirth;
    await _aiCtrl.fetchSuggestions(
      bodyRequest: {
        ApiKeys.profession: user?.profession,
        ApiKeys.designation: user?.designation,
        ApiKeys.date_of_birth_Obj: {
          ApiKeys.year: dob?.year,
          ApiKeys.month: dob?.month,
          ApiKeys.date: dob?.date,
        },
        ApiKeys.gender: user?.gender,
      },
      apiType: "bio",
      targetController: _bioController,
      onSaved: _validate,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await _personalCtrl.updateUserProfileDetails(
        params: {ApiKeys.bio: _bioController.text.trim()},
        isFromProfileOnly: true,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size10,
          bottom: SizeConfig.size20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTextColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Header — title + close.
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.bio.tr,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.large,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size8),

              // Label row — matches add_bio_via_ai_screen exactly: bio
              // label on the left, AI generate icon (or spinner) on
              // the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    AppStrings.aboutMeBio.tr,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(width: SizeConfig.size8),
                  InkWell(
                    onTap: _regenerateAi,
                    child: Obx(
                      () => _aiCtrl.isLoading.value
                          ? const SizedBox(
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
                            ),
                    ),
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
                textEditController: _bioController,
                maxLine: 5,
                isCounterVisible: true,
                onChange: (_) => _validate(),
              ),
              SizedBox(height: SizeConfig.paddingL),

              CustomBtn(
                radius: 10,
                title: _isSaving ? null : AppStrings.update,
                isLoading: _isSaving,
                onTap: _save,
                isValidate: _isValid,
              ),
              SizedBox(height: SizeConfig.paddingXSL),
            ],
          ),
        ),
      ),
    );
  }
}
