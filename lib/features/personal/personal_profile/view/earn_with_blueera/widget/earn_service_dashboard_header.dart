import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
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
import 'package:intl/intl.dart';

/// Twitter-style header for earn-service dashboards.
///
/// Renders edge-to-edge cover (with back + camera overlays and a circular
/// service logo) followed by profile info (name, joined date, type chip,
/// location, email, phone). Intended to be placed inside a
/// `SliverToBoxAdapter` so it scrolls away under the pinned TabBar.
class EarnServiceDashboardHeader extends StatelessWidget {
  final EarnProfileController controller;
  final VoidCallback? onBack;
  final Widget? profileSelector;

  const EarnServiceDashboardHeader({
    super.key,
    required this.controller,
    this.onBack,
    this.profileSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.earnProfile.value;
      final isFoodProfile = profile?.profileType == 'homeMadeFood';
      return Container(
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(context, profile),
            _buildProfileInfoSection(context, profile, isFoodProfile),
          ],
        ),
      );
    });
  }

  // ── Cover Section ────────────────────────────────────────
  Widget _buildCoverSection(BuildContext context, EarnProfileModel? profile) {
    final coverUrl = profile?.coverImage ?? '';
    final logoUrl = profile?.serviceLogo ?? '';

    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _coverPlaceholder(),
                    errorWidget: (_, __, ___) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (onBack != null) ...[
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (profileSelector != null) profileSelector!,
                const Spacer(),
                GestureDetector(
                  onTap: () => _onCoverEdit(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _onLogoEdit(context),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedAvatarWidget(
                      imageUrl: logoUrl.isEmpty ? null : logoUrl,
                      size: 80,
                      borderRadius: 40,
                      showProfileOnFullScreen: false,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: LocalAssets(
                        imagePath: AppIconAssets.editIcon,
                        height: SizeConfig.size12,
                        width: SizeConfig.size12,
                        imgColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ── Profile Info Section ─────────────────────────────────
  Widget _buildProfileInfoSection(
    BuildContext context,
    EarnProfileModel? profile,
    bool isFoodProfile,
  ) {
    final name = profile?.serviceName ?? '';
    final profileTypeLabel = _profileTypeLabel(profile?.profileType ?? '');
    final createdAt = profile?.createdAt ?? '';
    final address = _extractCityState((profile?.address ?? '').trim());
    final email = (profile?.email ?? '').trim();
    final phone = (profile?.alternatePhoneNumber ?? '').trim();
    final dietaryType = profile?.foodType ?? '';
    final distance = (profile?.latitude != null && profile?.longitude != null)
        ? calculateDistance(profile!.latitude!, profile.longitude!)
        : null;

    final showTypeRow = profileTypeLabel.isNotEmpty || isFoodProfile;
    final showContactBlock =
        address.isNotEmpty || email.isNotEmpty || phone.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            CustomText(
              name,
              fontSize: SizeConfig.extraLarge22,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            CustomText(
              'Joined ${_formatJoinedDate(createdAt)}',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w400,
            ),
          ],
          if (showTypeRow) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (isFoodProfile && dietaryType.isNotEmpty) ...[
                  _buildDietaryIndicator(dietaryType),
                  const SizedBox(width: 6),
                ],
                if (profileTypeLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: CustomText(
                      profileTypeLabel,
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
          ],
          if (showContactBlock) ...[
            const SizedBox(height: 10),
            if (address.isNotEmpty) ...[
              _infoRow(
                Icons.location_on_outlined,
                distance != null
                    ? '${distance.toStringAsFixed(2)} KM • $address'
                    : address,
              ),
              if (email.isNotEmpty || phone.isNotEmpty)
                const SizedBox(height: 6),
            ],
            if (email.isNotEmpty) ...[
              _infoRow(Icons.email_outlined, email),
              if (phone.isNotEmpty) const SizedBox(height: 6),
            ],
            if (phone.isNotEmpty) _infoRow(Icons.phone_outlined, phone),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryTextColor),
        const SizedBox(width: 5),
        Flexible(
          child: CustomText(
            text,
            fontSize: SizeConfig.medium15,
            color: AppColors.secondaryTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  // ── Helpers ──────────────────────────────────────────────
  String _extractCityState(String address) {
    if (address.isEmpty) return '';
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      final statePart = parts[parts.length - 2]
          .replaceAll(RegExp(r'\d{5,6}'), '')
          .trim();
      final city = parts[parts.length - 3].trim();
      if (city.isNotEmpty && statePart.isNotEmpty) return '$city, $statePart';
      return city.isNotEmpty ? city : statePart;
    }
    return address;
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
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

  // ── Image edit flows ─────────────────────────────────────
  Future<void> _onLogoEdit(BuildContext context) async {
    final path = await SelectProfilePictureDialog.showLogoDialog(
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
      final path = await SelectProfilePictureDialog.showLogoDialog(
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
                          color: isSelected ? optionColor : AppColors.greyE5,
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
                            FoodTypeIndicator(isVegetarian: isVeg, size: 6),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomText(option,
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color:
                                isSelected ? optionColor : AppColors.greyE5,
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
                final ok = await controller
                    .patchEarnProfile({'foodType': selectedType.value});
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
