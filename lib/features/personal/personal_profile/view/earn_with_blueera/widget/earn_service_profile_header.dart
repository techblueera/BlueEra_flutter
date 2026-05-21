import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

class EarnServiceProfileHeader extends StatelessWidget {
  final EarnProfileController controller;
  final bool isFoodProfile;
  final double rating;
  final int totalRatings;

  const EarnServiceProfileHeader({
    super.key,
    required this.controller,
    this.isFoodProfile = false,
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.earnProfile.value;
      return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSection(context, profile),
            _buildDetailsSection(context, profile),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  // ── Banner ────────────────────────────────────────────────
  Widget _buildBannerSection(BuildContext context, EarnProfileModel? profile) {
    final coverUrl = profile?.coverImage ?? '';
    final logoUrl = profile?.serviceLogo ?? '';

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
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey[200]),
                    )
                  : Container(color: Colors.grey[200]),
            ),
          ),
          Positioned(
            left: 16,
            top: 180,
            child: GestureDetector(
              onTap: () => _onLogoEdit(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: CachedAvatarWidget(
                      imageUrl: logoUrl.isEmpty ? null : logoUrl,
                      size: 70,
                      borderRadius: 35,
                      showProfileOnFullScreen: false,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryColor,
                        ),
                        child: LocalAssets(
                          imagePath: AppIconAssets.editIcon,
                          height: SizeConfig.size14,
                          width: SizeConfig.size14,
                          imgColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: GestureDetector(
              onTap: () => _onCoverEdit(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                  color: AppColors.mainTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Details ───────────────────────────────────────────────
  Widget _buildDetailsSection(
      BuildContext context, EarnProfileModel? profile) {
    final hasAddress = (profile?.address ?? '').trim().isNotEmpty;
    final dietaryType = profile?.foodType ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          CustomText(
            profile?.serviceName ?? '',
            fontSize: 20,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isFoodProfile && dietaryType.isNotEmpty) ...[
                _buildDietaryIndicator(dietaryType),
                const SizedBox(width: 6),
              ],
              if ((profile?.profileType ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    _profileTypeLabel(profile!.profileType!),
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (isFoodProfile && dietaryType.isEmpty) ...[
                const SizedBox(width: 6),
                _buildInlineAdd(
                  icon: Icons.restaurant_outlined,
                  label: 'Add Type',
                  onTap: () => _openDietaryTypeSheet(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _buildLocationInfoBlock(context, profile, hasAddress),
        ],
      ),
    );
  }

  Widget _buildLocationInfoBlock(
      BuildContext context, EarnProfileModel? profile, bool hasAddress) {
    final distance = (profile?.latitude != null && profile?.longitude != null)
        ? calculateDistance(profile!.latitude!, profile.longitude!)
        : null;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.near_me_rounded,
                size: 14, color: AppColors.primaryColor),
            const SizedBox(width: 5),
            CustomText(
              '${distance?.toStringAsFixed(2) ?? '--'} KM',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
            if (hasAddress) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomText('|',
                    fontSize: 11,
                    color: AppColors.secondaryTextColor
                        .withValues(alpha: 0.4)),
              ),
              Flexible(
                child: CustomText(
                  profile?.address,
                  fontSize: 11,
                  color: AppColors.secondaryTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Indicators ────────────────────────────────────────────
  Widget _buildDietaryIndicator(String type) {
    if (type.toLowerCase() == 'both') return _buildBothFoodIndicator();
    return FoodTypeIndicator(
      isVegetarian: type.toLowerCase() == 'veg',
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green00,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            height: 7,
            width: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red00,
            ),
          ),
        ],
      ),
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

  String _profileTypeLabel(String raw) {
    switch (raw) {
      case 'homeMadeFood':
        return 'Home Made Food';
      case 'homeMadeProduct':
        return 'Home Made Product';
      case 'homeService':
        return 'Home Service';
      default:
        return raw;
    }
  }

  // ── Image edit flows ──────────────────────────────────────
  Future<void> _onLogoEdit(BuildContext context) async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.uploadBusinessLogo.tr,
    ).catchError((_) => null);
    if (path == null || path.isEmpty) return;
    await controller.patchEarnProfileImage(
      uploadKey: 'serviceLogo',
      file: File(path),
    );
  }

  Future<void> _onCoverEdit(BuildContext context) async {
    try {
      final path = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture.tr,
      ).catchError((_) => null);
      if (path == null || path.isEmpty) {
        commonSnackBar(message: AppStrings.noImageSelected);
        return;
      }
      final file = File(path);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 75,
      );
      await controller.patchEarnProfileImage(
        uploadKey: 'coverImage',
        file: File(compressed?.path ?? path),
      );
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed);
    }
  }

  // ── Dietary type sheet ───────────────────────────────────
  void _openDietaryTypeSheet(BuildContext context) {
    final currentType = controller.earnProfile.value?.foodType ?? '';
    final selectedType = ValueNotifier<String>(currentType);
    final options = ['Veg', 'Non-Veg', 'Both'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => Container(
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
              children: const [
                CustomText('Select Type',
                    fontSize: 18, fontWeight: FontWeight.w600),
                CloseButton(),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: selectedType,
              builder: (_, selected, __) => Column(
                children: options.map((option) {
                  final isSelected = selected == option;
                  Color optionColor;
                  bool isVeg;
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
                          color:
                              isSelected ? optionColor : AppColors.greyE5,
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
                            child: CustomText(option,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
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
              ),
            ),
            const SizedBox(height: 16),
            CustomBtn(
              radius: 10,
              bgColor: AppColors.primaryColor,
              title: AppStrings.save,
              onTap: () async {
                if (selectedType.value.isEmpty) {
                  commonSnackBar(message: 'Please select a type');
                  return;
                }
                final ok = await controller.patchEarnProfile({
                  'foodType': selectedType.value,
                });
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }
}
