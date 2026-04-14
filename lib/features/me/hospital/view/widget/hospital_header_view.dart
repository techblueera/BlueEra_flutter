import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_about_us.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
  File? _bannerImage;
  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isBanner) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBanner) {
          _bannerImage = File(image.path);
        } else {
          _logoImage = File(image.path);
        }
      });
      if (isBanner) {
        await controller.uploadHospitalLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'coverUrl');
      } else {
        await controller.uploadHospitalLogoOrBannerImage(
            uploadFile: File(image.path), uploadVia: 'logoUrl');
      }
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
    final size = MediaQuery.of(context).size;
    return Obx(() {
      return CommonCardWidget(
        padding: 0,
        child: Column(
          children: [
            // --- HEADER SECTION (Banner & Logo) ---
            SizedBox(
              height: size.height * 0.18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner Image
                  GestureDetector(
                    onTap: () => null,
                    child: Container(
                      width: double.infinity,
                      height: size.height * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[100],
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        child: _bannerImage != null
                            ? Image.file(_bannerImage!,
                                fit: BoxFit.cover, width: double.infinity)
                            : (controller.hospitalDataResModel?.value.data
                                        ?.coverUrl?.isNotEmpty ??
                                    false)
                                ? Image.network(
                                    controller.hospitalDataResModel!.value.data!
                                        .coverUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(Icons.local_hospital,
                                          size: 48,
                                          color: Colors.blueGrey[300]),
                                    ),
                                  )
                                : Center(
                                    child: Icon(Icons.local_hospital,
                                        size: 48,
                                        color: Colors.blueGrey[300]),
                                  ),
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned(
                      right: 20,
                      top: 10,
                      child: IgnorePointer(
                        ignoring: widget.isReadOnly,
                        child: InkWell(
                          onTap: () => _pickImage(true),
                          child: Container(
                              width: 30,
                              height: 30,
                              child: LocalAssets(
                                imagePath: AppIconAssets.edit_banner_icon,
                              )),
                        ),
                      ),
                    ),

                  // Logo Image
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: IgnorePointer(
                      ignoring: widget.isReadOnly,
                      child: GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10)
                            ],
                          ),
                          child: ClipOval(
                            child: _logoImage != null
                                ? Image.file(_logoImage!,
                                    fit: BoxFit.cover, width: 80, height: 80)
                                : (controller.hospitalDataResModel?.value.data
                                            ?.logoUrl?.isNotEmpty ??
                                        false)
                                    ? Image.network(
                                        controller.hospitalDataResModel!.value
                                            .data!.logoUrl!,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (_, __, ___) =>
                                            _logoPlaceholder(),
                                      )
                                    : _logoPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned(
                        bottom: 0,
                        left: 75,
                        child: IgnorePointer(
                          ignoring: widget.isReadOnly,
                          child: InkWell(
                            onTap: () => _pickImage(false),
                            child: Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // color: AppColors.red00,
                                  color: AppColors.secondaryTextColor
                                      .withValues(alpha: 0.3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 15,
                                )),
                          ),
                        ))
                ],
              ),
            ),

            // --- NAME & STATS SECTION ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: SizeConfig.paddingXS),

                  // Hospital Name + Edit
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
                        ),
                    ],
                  ),

                  SizedBox(height: SizeConfig.paddingXSmall),

                  // Rating | Reviews | Distance row
                  _buildStatsRow(),

                  SizedBox(height: SizeConfig.paddingXS),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
