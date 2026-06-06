import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_local_gallery.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeMadeFoodProfileScreen extends StatefulWidget {
  const HomeMadeFoodProfileScreen({super.key});

  @override
  State<HomeMadeFoodProfileScreen> createState() =>
      _HomeMadeFoodProfileScreenState();
}

class _HomeMadeFoodProfileScreenState extends State<HomeMadeFoodProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _altContactController = TextEditingController();

  final Rxn<File> _logoFile = Rxn<File>();
  String? _selectedFoodType;
  bool _homeDelivery = false;
  bool _monthlyPayment = false;
  bool _acceptPrivacy = false;

  // Location data from search
  double _selectedLat = 0.0;
  double _selectedLng = 0.0;

  final RxList<String> _galleryImages = <String>[].obs;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _houseNumberController.dispose();
    _altContactController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: AppStrings.foodServiceLogo,
    );
    if (path != null) {
      _logoFile.value = File(path);
    }
  }

  Future<void> _pickGalleryImage() async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: AppStrings.uploadPhotoTitle,
    );
    if (path != null) {
      _galleryImages.add(path);
    }
  }

  final _controller = getOrPut(() => EarnProfileController());

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_logoFile.value == null) {
      commonSnackBar(message: AppStrings.pleaseSelectALogo.tr);
      return;
    }
    if (!_acceptPrivacy) {
      commonSnackBar(message: AppStrings.pleaseAcceptPrivacyAndContentPolicy.tr);
      return;
    }

    final galleryFiles = _galleryImages
        .map((path) => File(path))
        .toList();

    final success = await _controller.createEarnProfile(
      serviceName: _nameController.text.trim(),
      serviceLogo: _logoFile.value!,
      profileType: 'homeMadeFood',
      foodType: _selectedFoodType,
      address: _addressController.text.trim(),
      houseNumber: _houseNumberController.text.trim(),
      alternatePhoneNumber: _altContactController.text.trim().isNotEmpty
          ? _altContactController.text.trim()
          : null,
      homeDelivery: _homeDelivery,
      monthlyPayment: _monthlyPayment,
      lat: _selectedLat,
      lng: _selectedLng,
      galleryImages: galleryFiles.isNotEmpty ? galleryFiles : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.homeMadeFoodSection),
      bottomNavigationBar: _buildActionButtons(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8,
          vertical: SizeConfig.size16,
        ),
        child: CustomFormCard(
          padding: EdgeInsets.all(10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoPicker(),
                SizedBox(height: SizeConfig.size20),

                CommonTextField(
                  textEditController: _nameController,
                  title: AppStrings.yourServiceName,
                  hintText: AppStrings.egRahulTiffinCentre,
                  isValidate: true,
                ),
                SizedBox(height: SizeConfig.size16),

                _buildFoodTypeDropdown(),
                SizedBox(height: SizeConfig.size16),

                CommonTextField(
                  textEditController: _houseNumberController,
                  title: AppStrings.houseNumberLabel,
                  hintText: AppStrings.egMG12,
                ),
                SizedBox(height: SizeConfig.size16),

                CommonLocationSearchField(
                  controller: _addressController,
                  title: AppStrings.addressLabel,
                  hintText: AppStrings.egLucknowUtterPradesh,
                  isShowLeading: false,
                  onSelected: (placeId, lat, lng, address) {
                    _addressController.text = address;
                    _selectedLat = lat;
                    _selectedLng = lng;
                  },
                ),
                SizedBox(height: SizeConfig.size8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: UseCurrentLocationButton(
                    onResolved: (lat, lng, address) {
                      setState(() {
                        _addressController.text = address;
                        _selectedLat = lat;
                        _selectedLng = lng;
                      });
                    },
                  ),
                ),
                SizedBox(height: SizeConfig.size16),


                _buildAlternateContactField(),
                SizedBox(height: SizeConfig.size20),

                _buildToggleRow(
                  label: AppStrings.doYouProvideHomeDelivery,
                  value: _homeDelivery,
                  onChanged: (v) => setState(() => _homeDelivery = v),
                ),
                SizedBox(height: SizeConfig.size12),

                _buildToggleRow(
                  label: AppStrings.monthlyPaymentAccepted,
                  value: _monthlyPayment,
                  onChanged: (v) => setState(() => _monthlyPayment = v),
                ),
                SizedBox(height: SizeConfig.size20),

                EarnServiceLocalGallery(
                  images: _galleryImages,
                  onAddImage: _pickGalleryImage,
                ),
                SizedBox(height: SizeConfig.size20),

                _buildPrivacyCheckbox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Center(
      child: Obx(() {
        final file = _logoFile.value;
        return GestureDetector(
          onTap: _pickLogo,
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.fillColor,
                  border: Border.all(color: AppColors.greyE5),
                  image: file != null
                      ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: file == null
                    ? Icon(
                        Icons.camera_alt_outlined,
                        size: 32,
                        color: AppColors.secondaryTextColor,
                      )
                    : null,
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                AppStrings.foodServiceLogo,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: 2),
              CustomText(
                AppStrings.addYourBrandLogoOrProfilePicture,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFoodTypeDropdown() {
    final foodTypes = ['Veg', 'Non-Veg', 'Vegan', 'Both'];
    return CommonDropdownDialog<String>(
      items: foodTypes,
      selectedValue: _selectedFoodType,
      hintText: AppStrings.vegNonVegHint,
      title: AppStrings.selectFoodType,
      dialogTitle: AppStrings.foodTypeLabel,
      displayValue: (v) => v,
      showDownArrow: true,
      onChanged: (v) => setState(() => _selectedFoodType = v),
    );
  }

  Widget _buildAlternateContactField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.alternateContactNoOptional,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size6),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.greyE5),
                boxShadow: [AppShadows.textFieldShadow]
              ),
              child: CustomText(
                '+91',
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CommonTextField(
                textEditController: _altContactController,
                hintText: '1234567890',
                keyBoardType: TextInputType.phone,
                maxLength: 10,
                isValidate: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(
              label,
              fontSize: SizeConfig.medium,
              color: AppColors.mainTextColor,
            ),
          ),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
            containerHeight: 24,
            containerWidth: 40,
            circleSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptPrivacy,
            onChanged: (v) => setState(() => _acceptPrivacy = v ?? false),
            activeColor: AppColors.primaryColor,
            checkColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
              side: BorderSide(
                color: AppColors.greyE5
              )
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
              ),
              children: [
                TextSpan(text: '${AppStrings.acceptLabelEarn.tr} '),
                TextSpan(
                  text: AppStrings.privacyLabel.tr,
                  style: TextStyle(color: AppColors.primaryColor),
                ),
                TextSpan(text: ' ${AppStrings.andText.tr} '),
                TextSpan(
                  text: AppStrings.contentLabel.tr,
                  style: TextStyle(color: AppColors.primaryColor),
                ),
                TextSpan(text: ' ${AppStrings.policyLabel.tr}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(10.0),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomBtn(
                onTap: () => Navigator.of(context).pop(),
                title: AppStrings.cancel,
                bgColor: AppColors.white,
                textColor: AppColors.primaryColor,
                borderColor: AppColors.primaryColor,
                radius: 10.0,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: CustomBtn(
                onTap: _onCreate,
                title: AppStrings.create,
                bgColor: AppColors.primaryColor,
                textColor: AppColors.white,
                radius: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
