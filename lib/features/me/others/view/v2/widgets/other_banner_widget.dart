import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// Other-business cover-banner block — visually mirrors the medical/
/// hospital v2 banner widget. Picker → compress → upload via the
/// existing `uploadSchoolLogoOrBannerImage(uploadVia: 'coverUrl')`
/// helper on `BusinessProfileFullController`.
class OtherBannerWidget extends StatefulWidget {
  final BusinessProfileFullController controller;

  const OtherBannerWidget({super.key, required this.controller});

  @override
  State<OtherBannerWidget> createState() => _OtherBannerWidgetState();
}

class _OtherBannerWidgetState extends State<OtherBannerWidget> {
  bool _isUploading = false;

  Future<void> _onEditCover() async {
    if (_isUploading) return;
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture.tr,
        cropAspectRatio: const CropAspectRatio(width: 16, height: 9),
      );
      if (newPath == null || newPath.isEmpty) return;

      setState(() => _isUploading = true);

      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 75,
      );

      await widget.controller.uploadSchoolLogoOrBannerImage(
        uploadFile: File(compressed?.path ?? newPath),
        uploadVia: 'coverUrl',
      );
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed.tr);
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
            widget.controller.businessProfile.value?.profile?.coverUrl ?? '';
        final hasBanner = cover.isNotEmpty;
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
        border: Border.all(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: SizeConfig.size12,
            bottom: SizeConfig.size12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined,
                    size: 20, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText('Add Your Banner Here',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ],
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
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size4),
                CustomText('Edit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
