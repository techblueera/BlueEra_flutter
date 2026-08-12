import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/view/aadhaar_locked_field.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lightweight edit-profile sheet shown from each dashboard's identity-
/// card "Edit" chip (Self Employee, Social, Professionals, Rider,
/// Cab/Transport).
///
/// Scoped to the **identity-card fields only** — name / email / phone.
/// Bio and address have their own dedicated cards
/// ([ProfileBioCard], [ProfileLocationCard]) with their own update
/// bottom sheets, so we deliberately don't surface them here to avoid
/// two sources of truth.
///
/// Saves silently via
/// [PersonalCreateProfileController.updateUserProfileDetails] with
/// `showProgress: false` — the sheet shows its own inline loader on
/// the Save CTA.
class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  /// Convenience launcher used from each dashboard's identity-card
  /// Edit chip.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileBottomSheet(),
    );
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  final _viewCtrl = getOrPut(
    () => ViewPersonalDetailsController(),
    permanent: true,
  );

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _ready = false;
  bool _saving = false;

  /// Aadhaar-verified accounts can't retype the name the card established.
  bool get _identityLocked => _viewCtrl.isAadhaarVerified;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Hydrate from in-memory controller state on the next frame so the
    // sheet animation isn't blocked by widget construction.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _hydrate();
      // The Aadhaar lock is read off the rider onboarding record, which this
      // sheet's hosts don't all load. Resolved BEFORE the form is revealed —
      // the sheet is already showing its loader, and painting the name field
      // editable and then locking it a moment later is worse than waiting.
      // Cache-first, so normally this returns without a network call.
      await _viewCtrl.ensureAadhaarStatusLoaded();
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  void _hydrate() {
    final user = _viewCtrl.personalProfileDetails.value.user;
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.contactNo ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    final user = _viewCtrl.personalProfileDetails.value.user;
    final params = <String, dynamic>{};

    final newName = _nameController.text.trim();
    // Never send the name for a verified account, even if something managed to
    // change the field — the read-only input is the affordance, this is the
    // guarantee.
    if (!_identityLocked &&
        newName.isNotEmpty &&
        newName != (user?.name ?? '')) {
      params[ApiKeys.name] = newName;
    }
    final newEmail = _emailController.text.trim();
    if (newEmail != (user?.email ?? '')) {
      params[ApiKeys.email] = newEmail;
    }
    final newPhone = _phoneController.text.trim();
    if (newPhone != (user?.contactNo ?? '')) {
      params[ApiKeys.phone] = newPhone;
    }

    if (params.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    await _personalCtrl.updateUserProfileDetails(
      params: params,
      isFromProfileOnly: true,
      showProgress: false,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SafeArea(
            top: false,
            child: _ready ? _buildForm() : _buildLoader(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return SizedBox(
      height: 240,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.editProfile,
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              const CloseButton(),
            ],
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(AppStrings.fullName),
                // Locked once the Aadhaar is verified — the card is the
                // authority on the holder's name, and letting it be retyped
                // here would undo that. The backend refuses the write anyway;
                // this stops the user finding that out after typing.
                AadhaarLockedField(
                  locked: _identityLocked,
                  child: CommonTextField(
                    textEditController: _nameController,
                    hintText: AppStrings.enterFullName,
                    isValidate: false,
                    readOnly: _identityLocked,
                  ),
                ),
                const SizedBox(height: 12),
                _label(AppStrings.email),
                CommonTextField(
                  textEditController: _emailController,
                  hintText: AppStrings.enterEmailAddress,
                  keyBoardType: TextInputType.emailAddress,
                  isValidate: false,
                ),
                const SizedBox(height: 12),
                _label(AppStrings.phoneNumber),
                CommonTextField(
                  textEditController: _phoneController,
                  hintText:AppStrings.enterPhoneNumberHint,
                  keyBoardType: TextInputType.phone,
                  isValidate: false,
                  inputLength: 10,
                ),
                const SizedBox(height: 16),
                CustomBtn(
                  radius: 10,
                  bgColor: AppColors.primaryColor,
                  isLoading: _saving,
                  title: AppStrings.save.tr,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: CustomText(
        text,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.mainTextColor,
      ),
    );
  }
}
