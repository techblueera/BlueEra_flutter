import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_about_us.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HospitalHeaderView extends StatefulWidget {
  final bool isReadOnly;

  const HospitalHeaderView({
    super.key,
    required this.isReadOnly,
  });

  @override
  State<HospitalHeaderView> createState() => _HospitalHeaderViewState();
}

class _HospitalHeaderViewState extends State<HospitalHeaderView> {
  final controller = Get.find<HospitalServiceAiController>();
  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isBanner) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (!isBanner) _logoImage = File(image.path);
      });
      await controller.uploadHospitalLogoOrBannerImage(
        uploadFile: File(image.path),
        uploadVia: isBanner ? 'coverUrl' : 'logoUrl',
      );
    }
  }

  /// Stats row: Rating | Reviews | Distance
  Widget _buildStatsRow() {
    final coordinates = controller.hospitalDataResModel?.value.data?.contacts
        ?.firstOrNull?.branch?.location?.coordinates;

    String? distanceText;
    if (coordinates != null && coordinates.length >= 2) {
      final lat = coordinates[1];
      final lng = coordinates[0];
      if (lat != 0.0 && lng != 0.0) {
        final km = calculateDistance(lat, lng);
        if (km != null) {
          distanceText = "${km.toStringAsFixed(1)} KM";
        }
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: SizeConfig.paddingXS,
      runSpacing: SizeConfig.paddingXSmall,
      children: [
        // Rating
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded,
                size: SizeConfig.size16, color: AppColors.yellow00),
            SizedBox(width: SizeConfig.size2),
            CustomText(
              "N/A",
              fontSize: SizeConfig.small,
              color: AppColors.yellow00,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),

        _statDot(),

        // Reviews
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                size: SizeConfig.size14, color: AppColors.secondaryTextColor),
            SizedBox(width: SizeConfig.size3),
            CustomText(
              "0 Reviews",
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),

        if (distanceText != null) ...[
          _statDot(),

          // Distance
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined,
                  size: SizeConfig.size14, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size2),
              CustomText(
                distanceText,
                fontSize: SizeConfig.small,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.secondaryTextColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey[200],
      child: Icon(Icons.local_hospital, size: 40, color: Colors.blueGrey[300]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return CommonCardWidget(
        padding: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingS,
            vertical: SizeConfig.paddingS,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- LOGO (with optional camera badge for edit mode) ---
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IgnorePointer(
                    ignoring: widget.isReadOnly,
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        child: ClipOval(
                          child: _logoImage != null
                              ? Image.file(_logoImage!,
                                  fit: BoxFit.cover, width: 70, height: 70)
                              : (controller.hospitalDataResModel?.value.data
                                          ?.logoUrl?.isNotEmpty ??
                                      false)
                                  ? Image.network(
                                      controller.hospitalDataResModel!.value
                                          .data!.logoUrl!,
                                      fit: BoxFit.cover,
                                      width: 70,
                                      height: 70,
                                      errorBuilder: (_, __, ___) =>
                                          _logoPlaceholder(),
                                    )
                                  : _logoPlaceholder(),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor,
                            border:
                                Border.all(color: AppColors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: SizeConfig.paddingM),

              // --- NAME & STATS ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomText(
                            controller.hospitalDataResModel?.value.data?.name ??
                                "",
                            fontSize: SizeConfig.large18,
                            maxLines: 2,
                            color: AppColors.mainTextColor,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.isReadOnly)
                          IconButton(
                            onPressed: () =>
                                Get.to(const HospitalAboutUsScreen()),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingXSmall),
                    _buildStatsRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
