import 'dart:async';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/ai_document_verification_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/controller/aadhaar_manual_kyc_controller.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/view/aadhaar_photo_section.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/languge_list_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Mandatory Aadhaar step between choosing a Gig Work profession and filling in
/// the personal profile.
///
/// Gig work puts someone in a customer's vehicle or at their door, so the
/// identity behind the account is checked BEFORE the profile exists rather
/// than as a document uploaded afterwards. There is no skip — the only ways
/// off this screen are a completed verification or going back to the
/// profession list.
///
/// **Number + card photos only. There is deliberately no OTP path here.**
/// OKYC needs a code delivered to the Aadhaar-linked mobile, which for this
/// audience is often a number they no longer hold — and a signup that can dead
/// end on an SMS that never arrives is a signup that gets abandoned. The photo
/// check answers the same question (is this card real, and is this number on
/// it) without depending on anyone else's delivery. The rider flow keeps its
/// OTP option; this is the one-way-in version for onboarding.
///
/// The verifier reads the holder's name and date of birth off the card, and
/// those are forwarded to [PersonalAccountNewScreen] to save retyping what the
/// Aadhaar already stated.
///
/// Only the gig-work branch of `create_account_type_v2_screen.dart` routes
/// here; every other profession goes straight to the profile form, and rider
/// onboarding (`rider_service_screen.dart`) is untouched.
class GigWorkAadhaarScreen extends StatefulWidget {
  const GigWorkAadhaarScreen({
    super.key,
    required this.accountType,
    required this.profileType,
    required this.profession,
    required this.professionTagId,
  });

  final String accountType;
  final IndividualProfileType profileType;
  final String profession;
  final String professionTagId;

  @override
  State<GigWorkAadhaarScreen> createState() => _GigWorkAadhaarScreenState();
}

class _GigWorkAadhaarScreenState extends State<GigWorkAadhaarScreen> {
  final LanguageListController langController =
      getOrPut(() => LanguageListController());

  final _formKey = GlobalKey<FormState>();

  late final AadhaarManualKycController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AadhaarManualKycController(
      onManualVerified: (aadhaar, front, back) async {
        // Deliberately NOT awaited. This callback gates the verified stage,
        // and the rider bridge behind it re-uploads both card images to S3
        // before its PUT — seconds of waiting on a screen whose work is
        // already done. The AI check has passed by this point, so the answer
        // the user is waiting for is settled; the bridge is bookkeeping for a
        // flow they have not reached yet. Fired and left to finish on its own
        // so the profile form opens immediately.
        //
        // Safe to outlive this screen: it holds no BuildContext, and the
        // controller instance stays alive for the request's duration because
        // the pending future references it.
        unawaited(_recordForRiderOnboarding(aadhaar, front: front, back: back));
      },
    );
  }

  @override
  void dispose() {
    _controller.disposeFlow();
    super.dispose();
  }

  /// Marks the rider onboarding "aadhar" step complete.
  ///
  /// The AI check verifies the identity but does NOT flip that step —
  /// `rider_service_screen` reads `onboarding/status`, whose `aadhar` flag
  /// only moves on the personal-identification PUT. Without this, a gig worker
  /// who verified during signup is asked for the same Aadhaar again the first
  /// time they open the rider flow.
  ///
  /// `getOrPut` at call time, not on mount: [DeliveryPartnerController] has no
  /// `onInit`, so constructing it costs nothing and fires no rider APIs, but
  /// there is still no reason to register it for someone merely browsing this
  /// screen.
  ///
  /// Failure is swallowed by the controller — signup continues either way.
  Future<void> _recordForRiderOnboarding(
    String aadhaarNumber, {
    File? front,
    File? back,
  }) async {
    await getOrPut(() => DeliveryPartnerController())
        .recordAadhaarForRiderOnboarding(
      aadhaarNumber: aadhaarNumber,
      front: front,
      back: back,
    );
  }

  bool get _hasBothImages =>
      _controller.frontImage.value != null &&
      _controller.backImage.value != null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _controller.submitWithNumber(_controller.aadharController.text);
    if (!mounted) return;
    // Only a clean pass advances the stage; anything else left the user on the
    // form with the reason in a snackbar.
    if (_controller.stage.value == AadhaarManualStage.verified) {
      _continueToProfile();
    }
  }

  /// Moves to the profile form, carrying whatever the card told us.
  ///
  /// `toNamed`, so this screen STAYS on the stack: back from the profile form
  /// lands here, on the Aadhaar step, rather than skipping the whole thing and
  /// dumping the user back on the profession list. It reopens with the number,
  /// the consent tick and both photos still in place — the controller outlives
  /// the pop — so they can look at what was submitted, or re-submit, without
  /// starting the step again.
  ///
  /// Name, gender and date of birth are whatever the verifier could read; any
  /// can be null, and the profile form fills what arrives and leaves the rest.
  void _continueToProfile() {
    final AiExtractedIdentity? extracted = _controller.extractedIdentity.value;
    final name = extracted?.name?.trim();

    Get.toNamed(
      RouteHelper.getPersonalAccountNewScreenRoute(),
      arguments: {
        ApiKeys.argAccountType: widget.accountType,
        ApiKeys.argProfileType: widget.profileType,
        ApiKeys.argProfessionTagId: widget.professionTagId,
        ApiKeys.argProfession: widget.profession,
        ApiKeys.argPrefillName: (name?.isEmpty ?? true) ? null : name,
        ApiKeys.argPrefillGender: _parseGender(extracted?.gender),
        ApiKeys.argPrefillDateOfBirth: extracted?.parsedDateOfBirth,
      },
    );
  }

  /// The card's gender as a [GenderType], or null when it says something this
  /// form has no option for.
  ///
  /// Deliberately NOT `GenderTypeExtension.fromString`, which answers `Male`
  /// for anything it doesn't recognise. That default is harmless on a dropdown
  /// the user can change; here the value gets locked, so an unreadable or
  /// unlisted gender would silently record the wrong one with no way to fix
  /// it. Null instead — the dropdown stays empty and editable.
  GenderType? _parseGender(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'male':
        return GenderType.Male;
      case 'female':
        return GenderType.Female;
      case 'other':
      case 'others':
        return GenderType.Others;
      default:
        return null;
    }
  }

  Future<void> _pickCardSide(Rxn<File> target, String title) async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: title,
      cropAspectRatio: CommonImageUploadTile.documentCropAspectRatio,
    );
    if (path != null && path.isNotEmpty) target.value = File(path);
  }

  /// Opens the picked side full screen, so the photo can be checked for
  /// legibility before it is submitted.
  void _viewCardSide(Rxn<File> target, String title) {
    final file = target.value;
    if (file == null) return;
    Get.to(() => ImageViewScreen(
          appBarTitle: title,
          imageUrls: [file.path],
          initialIndex: 0,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: CommonBackAppBar(
        isLeading: true,
        appBarColor: AppColors.white,
        title: langController.tr('Verify Your Aadhaar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _intro(),
              SizedBox(height: SizeConfig.size16),
              CustomFormCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CommonTextField(
                        textEditController: _controller.aadharController,
                        title: AppStrings.aadharNumber.tr,
                        hintText: AppStrings.egAadharNo.tr,
                        keyBoardType: TextInputType.number,
                        validator: ValidationMethod.validateAadhaar,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        maxLength: 12,
                      ),
                      SizedBox(height: SizeConfig.paddingS),
                      _consentRow(),
                      SizedBox(height: SizeConfig.paddingM),
                      // NOT wrapped in an Obx. The section reads nothing
                      // observable at this level — each capture frame owns an
                      // Obx over its own image, and the submit button owns one
                      // that reads `isSubmitting` and calls [hasBothImages].
                      // An Obx here would find no observable to track and trip
                      // GetX's "improper use of a GetX" assertion.
                      AadhaarPhotoSection(
                        frontImage: _controller.frontImage,
                        backImage: _controller.backImage,
                        isSubmitting: _controller.isSubmitting,
                        hasBothImages: () => _hasBothImages,
                        onPickFront: () => _pickCardSide(
                            _controller.frontImage, AppStrings.aadharFront.tr),
                        onPickBack: () => _pickCardSide(
                            _controller.backImage, AppStrings.aadharBack.tr),
                        onViewFront: () => _viewCardSide(
                            _controller.frontImage, AppStrings.aadharFront.tr),
                        onViewBack: () => _viewCardSide(
                            _controller.backImage, AppStrings.aadharBack.tr),
                        onSubmit: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Consent — mandatory, never pre-ticked (compliance requirement).
  Widget _consentRow() {
    return Obx(
      () => InkWell(
        onTap: () => _controller.consentGiven.toggle(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _controller.consentGiven.value,
                onChanged: (v) => _controller.consentGiven.value = v ?? false,
                activeColor: AppColors.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                checkColor: Colors.white,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                AppStrings.aadhaarConsentDeclaration.tr,
                fontSize: SizeConfig.small,
                color: AppColors.coloGreyText,
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Says why the step exists before asking for the number. A KYC wall with no
  /// stated reason is where onboarding gets abandoned.
  Widget _intro() {
    return CustomFormCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: SizeConfig.size44,
            width: SizeConfig.size44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.skyBlueE4,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              color: AppColors.primaryColor,
              size: SizeConfig.size22,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  langController.tr('Identity check required'),
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size4),
                CustomText(
                  langController.tr(
                    'Gig work means riding, driving or delivering for '
                    'customers, so we verify who you are before your profile '
                    'is created. Enter your Aadhaar number and upload photos '
                    'of both sides of the card.',
                  ),
                  fontSize: SizeConfig.size12,
                  color: AppColors.secondaryTextColor,
                  maxLines: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
