import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lightweight edit-profile sheet shown from the various dashboard "Edit"
/// chips (Self Employee, Social, Professionals, Rider, Cab/Transport).
///
/// The full [UpdateProfileScreen] is heavy and calls the profession-list
/// API on open which adds 1+ second of perceived lag — for the common
/// "tweak my profile" path users only need name / designation / bio /
/// address / email / phone, so this sheet keeps it focused and saves
/// silently via [PersonalCreateProfileController.updateUserProfileDetails]
/// (no global progress dialog, no extra navigation).
class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  /// Convenience launcher used from each dashboard's `_openEditProfile`.
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
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Hydrate from in-memory controller state on the next frame so the
    // sheet animation isn't blocked by widget construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrate();
      setState(() => _ready = true);
    });
  }

  void _hydrate() {
    final user = _viewCtrl.personalProfileDetails.value.user;
    _nameController.text = user?.name ?? '';
    _bioController.text = user?.bio ?? '';
    _locationController.text = user?.address ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.contactNo ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
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
    if (newName.isNotEmpty && newName != (user?.name ?? '')) {
      params[ApiKeys.name] = newName;
    }
    final newBio = _bioController.text.trim();
    if (newBio != (user?.bio ?? '')) {
      params[ApiKeys.bio] = newBio;
    }
    final newAddress = _locationController.text.trim();
    if (newAddress != (user?.address ?? '')) {
      params[ApiKeys.address] = newAddress;
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
                'Edit Profile',
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
                _label('Name'),
                CommonTextField(
                  textEditController: _nameController,
                  hintText: 'Your full name',
                  isValidate: false,
                ),
                const SizedBox(height: 12),
                _label('Bio'),
                CommonTextField(
                  textEditController: _bioController,
                  hintText: 'Write something about yourself...',
                  maxLine: 4,
                  maxLength: 900,
                  isValidate: false,
                  isCounterVisible: true,
                  keyBoardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                _label(AppStrings.location.tr),
                CommonLocationSearchField(
                  controller: _locationController,
                  hintText: 'E.g. Ranchi, Jharkhand...',
                  isShowLeading: false,
                  title: '',
                  onSelected: (placeId, lat, lng, address) {
                    _locationController.text = address;
                  },
                ),
                const SizedBox(height: 12),
                _label('Email'),
                CommonTextField(
                  textEditController: _emailController,
                  hintText: 'name@example.com',
                  keyBoardType: TextInputType.emailAddress,
                  isValidate: false,
                ),
                const SizedBox(height: 12),
                _label('Phone'),
                CommonTextField(
                  textEditController: _phoneController,
                  hintText: '10-digit number',
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
