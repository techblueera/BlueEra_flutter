import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_availability_widget.dart';
import 'package:BlueEra/features/business/widgets/business_card_ui.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/features/business/widgets/business_hours_sheet_content.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_visting_cards.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/fetch_location_button.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import '../../../core/api/apiService/api_keys.dart';

class BusinessProfileHeaderView extends StatelessWidget {
  final BusinessProfileDetails? details;
  final ViewBusinessDetailsController controller;
  final bool isRestaurantProfile;

  const BusinessProfileHeaderView({
    super.key,
    required this.details,
    required this.controller,
    this.isRestaurantProfile = false,
  });

  String get _coverImageUrl {
    final cover = controller.coverImage?.value;
    if (cover != null && cover.isNotEmpty) return cover;
    final profile = controller.imagePath?.value;
    if (profile != null && profile.isNotEmpty) return profile;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBannerSection(context),
          _buildDetailsSection(context),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: Image.network(
                _coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 180,
            child: CommonProfileImage(
              imagePath: controller.imagePath?.value ?? "",
              onImageUpdate: _onProfileImageUpdate,
              dialogTitle: AppStrings.uploadBusinessLogo.tr,
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: InkWell(
              onTap: () => _onCoverImageEdit(context),
              child: Image.asset('assets/images/camera.png'),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 5,
            child: BusinessCardUi(
              onTap: () => Get.to(() => AllVisitingCards(
                  businessDetails: details, showAppBar: true)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final hasAvailability = details?.availability?.schedule != null;
    final hasWebsite =
        details?.websiteUrl != null && details!.websiteUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ── Name ──
          CustomText(details?.businessName,
              fontSize: 20,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.bold),
          const SizedBox(height: 8),

          // ── Category + Rating + Dietary (inline) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isRestaurantProfile && _hasDietaryType) ...[
                _buildDietaryIndicator(),
                const SizedBox(width: 6),
              ],
              BusinessCommonSubCategoryWidget(
                label: details?.subCategoryDetails?.name,
              ),
              const SizedBox(width: 5),
              CommonRatingRow(
                rating: double.tryParse(
                        details?.avg_rating.toString() ?? '0.0') ??
                    0.0,
                reviews: details?.total_ratings?.toInt() ?? 0,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Location info block ──
          _buildLocationInfoBlock(context),
          const SizedBox(height: 10),

          // ── Website ──
          if (hasWebsite)
            InkWell(
              onTap: () => launchURL(details!.websiteUrl!),
              child: Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: CustomText(
                      details?.websiteUrl,
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          else
            _buildInlineAdd(
              icon: Icons.link_rounded,
              label: 'Add Website',
              onTap: () => _openEditSheet(context),
            ),
          const SizedBox(height: 10),

          // ── Availability + Restaurant type ──
          _buildQuickInfoRow(context, hasAvailability),
        ],
      ),
    );
  }

  Widget _buildLocationInfoBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance + locality
          Row(
            children: [
              Icon(Icons.near_me_rounded,
                  size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 5),
              CustomText(
                '${calculateDistance(
                  details?.businessLocation?.lat?.toDouble() ?? 0.0,
                  details?.businessLocation?.lon?.toDouble() ?? 0.0,
                )?.toStringAsFixed(2) ?? '--'} KM',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              if (_hasAddress) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CustomText('|',
                      fontSize: 11,
                      color: AppColors.secondaryTextColor
                          .withValues(alpha: 0.4)),
                ),
                Expanded(
                  child: CustomText(
                    getLocalityAddress(details?.address),
                    fontSize: 11,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (!_hasAddress)
                Expanded(
                  child: InkWell(
                    onTap: () => _openAddressEditSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CustomText(
                        '+ ${AppStrings.addAddress.tr}',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoRow(BuildContext context, bool hasAvailability) {
    final List<Widget> items = [];

    // Availability
    if (hasAvailability) {
      items.add(Expanded(
        child: BusinessAvailabilityWidget(
          hasAvailability: true,
          schedule: details?.availability?.schedule,
          onEditTap: () => _openBusinessHoursEditSheet(context),
          onAddTap: () => _openBusinessHoursEditSheet(context),
        ),
      ));
    } else {
      items.add(_buildInlineAdd(
        icon: Icons.calendar_today_outlined,
        label: 'Add Visiting Days',
        onTap: () => _openBusinessHoursEditSheet(context),
      ));
    }

    // Restaurant type (only for restaurant profiles)
    if (isRestaurantProfile && !_hasDietaryType) {
      items.add(const SizedBox(width: 10));
      items.add(_buildInlineAdd(
        icon: Icons.restaurant_outlined,
        label: 'Add Type',
        onTap: () => _openDietaryTypeSheet(context),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildInlineAdd({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryColor),
            const SizedBox(width: 3),
            CustomText(
              label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasAddress =>
      details?.address != null && details!.address!.trim().isNotEmpty;



  bool get _hasDietaryType =>
      details?.dietaryType != null && details!.dietaryType!.trim().isNotEmpty;

  Widget _buildDietaryIndicator() {
    if (details!.dietaryType == 'Both') {
      return _buildBothFoodIndicator();
    }
    return FoodTypeIndicator(
      isVegetarian: details!.dietaryType == 'Veg',
      size: 7,
    );
  }

  Widget _buildBothFoodIndicator() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green00,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red00,
            ),
          ),
        ],
      ),
    );
  }

  void _openDietaryTypeSheet(BuildContext context) {
    final currentType = details?.dietaryType ?? '';
    final selectedType = ValueNotifier<String>(currentType);
    final options = ['Veg', 'Non-Veg', 'Both'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    'Select Restaurant Type',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: selectedType,
                builder: (_, selected, __) {
                  return Column(
                    children: options.map((option) {
                      final isSelected = selected == option;
                      final Color optionColor;
                      final bool isVeg;

                      switch (option) {
                        case 'Veg':
                          optionColor = AppColors.green00;
                          isVeg = true;
                          break;
                        case 'Non-Veg':
                          optionColor = AppColors.red00;
                          isVeg = false;
                          break;
                        default:
                          optionColor = Colors.orange;
                          isVeg = true;
                      }

                      return InkWell(
                        onTap: () => selectedType.value = option,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? optionColor
                                  : AppColors.greyE5,
                              width: isSelected ? 1.5 : 1,
                            ),
                            color: isSelected
                                ? optionColor.withValues(alpha: 0.06)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              if (option == 'Both')
                                _buildBothFoodIndicator()
                              else
                                FoodTypeIndicator(
                                    isVegetarian: isVeg, size: 6),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  option,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? optionColor
                                    : AppColors.greyE5,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomBtn(
                radius: 10,
                bgColor: AppColors.primaryColor,
                title: AppStrings.save,
                onTap: () async {
                  if (selectedType.value.isEmpty) {
                    commonSnackBar(message: 'Please select a restaurant type');
                    return;
                  }
                  final params = <String, dynamic>{
                    ApiKeys.businessId: businessId,
                    ApiKeys.dietaryType: selectedType.value,
                  };
                  await controller.updateBusinessDetails(params);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onProfileImageUpdate(String image) async {
    controller.imagePath?.value = image;
    dio.MultipartFile? imageByPart;
    if (controller.imagePath?.value.isNotEmpty ?? false) {
      final fileName = controller.imagePath?.value.split('/').last ?? "";
      imageByPart = await dio.MultipartFile.fromFile(
          controller.imagePath?.value ?? "",
          filename: fileName);
    }
    final reqData = {
      ApiKeys.businessId: businessId,
      ApiKeys.logo_image: imageByPart,
    };
    await controller.updateBusinessDetails(reqData);
  }

  Future<void> _onCoverImageEdit(BuildContext context) async {
    try {
      final newPath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        AppStrings.editCoverPicture.tr,
        cropAspectRatio: CropAspectRatio(width: 3, height: 1),
      ).catchError((_) => null);

      if (newPath == null || newPath.isEmpty) {
        commonSnackBar(message: AppStrings.noImageSelected);
        return;
      }

      controller.coverImage?.value = newPath;

      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );

      final dataImage = await multiPartImage(
        imagePath: compressed?.path ?? newPath,
      );

      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed);
        return;
      }

      final reqProfile = {
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: details?.businessName,
        ApiKeys.coverimg: dataImage,
      };
      await controller.updateBusinessProfileDetails(reqProfile);
    } catch (e) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  ADDRESS EDIT BOTTOM SHEET
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _openAddressEditSheet(BuildContext context) {
    final addressController =
        TextEditingController(text: details?.address ?? '');
    final cityController =
        TextEditingController(text: details?.cityStatePincode ?? '');
    final pincodeController =
        TextEditingController(text: details?.pincode?.toString() ?? '');
    final locationController = Get.put(LocationController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        _hasAddress
                            ? AppStrings.updateAddress.tr
                            : AppStrings.addAddress.tr,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      const CloseButton(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fetch location button
                  CommonLocationFetcher(
                    locationController: locationController,
                    onLocationFetched: (LocationDataModel locationData) {
                      addressController.text = locationData.fullAddress;
                      cityController.text = locationData.city;
                      pincodeController.text = locationData.pinCode;
                      controller.addressLat?.value =
                          double.parse(locationData.lat);
                      controller.addressLong?.value =
                          double.parse(locationData.long);
                    },
                    childBuilder: (fetchAction) {
                      return PositiveCustomBtn(
                        width: double.infinity,
                        height: SizeConfig.size40,
                        onTap: fetchAction,
                        isLeadingShow: true,
                        leadingIconPath: AppIconAssets.refreshIcon,
                        title: AppStrings.yourBusinessLiveLocation.tr,
                        radius: 8.0,
                        bgColor: AppColors.primaryColor,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  CommonTextField(
                    textEditController: addressController,
                    maxLine: 3,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: AppStrings.fullBusinessAddress,
                    hintText: AppStrings.addressHint,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size16),

                  CommonTextField(
                    textEditController: cityController,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                    title: AppStrings.city,
                    hintText: AppStrings.city,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size16),

                  CommonTextField(
                    textEditController: pincodeController,
                    inputLength: AppConstants.inputCharterLimit6,
                    keyBoardType: TextInputType.number,
                    regularExpression: RegularExpressionUtils.digitsPattern,
                    title: AppStrings.pincodeTitle,
                    hintText: AppStrings.pincodeHint,
                    isValidate: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.pleaseEnterPinCode.tr;
                      } else if (!RegExp(RegularExpressionUtils.pinCodeRegExp)
                          .hasMatch(value)) {
                        return AppStrings.enterValidIndianPincode.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  CustomBtn(
                    radius: 10,
                    bgColor: AppColors.primaryColor,
                    title: AppStrings.save,
                    onTap: () async {
                      if (addressController.text.trim().isEmpty ||
                          cityController.text.trim().isEmpty ||
                          pincodeController.text.trim().isEmpty) {
                        commonSnackBar(
                            message: AppStrings.noAddressFound.tr);
                        return;
                      }

                      final params = <String, dynamic>{
                        ApiKeys.businessId: businessId,
                        ApiKeys.address: addressController.text.trim(),
                        ApiKeys.city_state_pincode:
                            cityController.text.trim(),
                        ApiKeys.pincode: pincodeController.text.trim(),
                        ApiKeys.business_location: jsonEncode({
                          ApiKeys.lat: controller.addressLat?.value
                              .toString(),
                          ApiKeys.lon: controller.addressLong?.value
                              .toString(),
                        }),
                      };
                      await controller.updateBusinessDetails(params);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUSINESS HOURS & WEBSITE EDIT BOTTOM SHEET
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _openBusinessHoursEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return BusinessHoursSheetContent(
          details: details,
          controller: controller,
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  WEBSITE EDIT BOTTOM SHEET
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _openEditSheet(BuildContext context) {
    final websiteController =
        TextEditingController(text: details?.websiteUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText(
                        'Update Website',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      const CloseButton(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  HttpsTextField(
                    controller: websiteController,
                    title: 'Website URL',
                    hintText: 'e.g. https://www.example.com',
                    isUrlValidate: true,
                  ),
                  const SizedBox(height: 24),
                  CustomBtn(
                    radius: 10,
                    bgColor: AppColors.primaryColor,
                    title: AppStrings.save,
                    onTap: () async {
                      final params = <String, dynamic>{
                        ApiKeys.businessId: businessId,
                        ApiKeys.website_url: websiteController.text.trim(),
                      };
                      await controller.updateBusinessProfileDetails(params);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

