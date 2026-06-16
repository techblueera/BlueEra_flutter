import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Vehicle cover-banner block — visual echo of `HospitalBannerWidget`.
/// Tapping the empty state or the filled banner opens the gallery
/// picker; the picked image is uploaded through the vehicle service's
/// presigned-PUT flow and persisted on the owner's profile
/// (`coverPicture`), so it stays in sync with the public profile preview.
class VehicleBannerWidget extends StatefulWidget {
  final VehicleController controller;

  const VehicleBannerWidget({super.key, required this.controller});

  @override
  State<VehicleBannerWidget> createState() => _VehicleBannerWidgetState();
}

class _VehicleBannerWidgetState extends State<VehicleBannerWidget> {
  final ViewPersonalDetailsController _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final PersonalCreateProfileController _personalCtrl =
      getOrPut(() => PersonalCreateProfileController());

  bool _isUploading = false;

  Future<void> _onEditCover() async {
    if (_isUploading) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);

      final url = await widget.controller.uploadFile(File(picked.path));
      if (url == null) return;
      await _personalCtrl.updateUserProfileDetails(
        params: {ApiKeys.coverimg: url},
        isFromProfileOnly: true,
      );
    } catch (_) {
      // Picker / upload failures already surface a snackbar from the
      // controller; swallow PlatformExceptions so the screen never crashes.
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Obx(() {
        final cover =
            _viewCtrl.personalProfileDetails.value.user?.coverPicture ?? '';
        final hasBanner = cover.trim().isNotEmpty;

        return GestureDetector(
          onTap: _onEditCover,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasBanner ? _filledBanner(cover) : _emptyBanner(),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _emptyBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE3ECF7),
        border: Border.all(color: AppColors.primaryColor, width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 26, color: AppColors.primaryColor),
            SizedBox(height: SizeConfig.size6),
            CustomText(
              AppStrings.coverPhoto.tr,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledBanner(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade100),
          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
        Positioned(
          right: SizeConfig.size10,
          bottom: SizeConfig.size10,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  AppStrings.edit.tr,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
