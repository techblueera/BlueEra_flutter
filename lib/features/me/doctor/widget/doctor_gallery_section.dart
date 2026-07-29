import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// "Gallery" card with the Add Photo action.
///
/// Backed by `Business.live_photos` (user-service), the same store the rest of
/// the app's business galleries use — nothing gallery-related lives on the
/// doctor profile.
class DoctorGallerySection extends StatefulWidget {
  const DoctorGallerySection({super.key});

  @override
  State<DoctorGallerySection> createState() => _DoctorGallerySectionState();
}

class _DoctorGallerySectionState extends State<DoctorGallerySection> {
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  bool _isUploading = false;

  Future<void> _addPhoto() async {
    if (_isUploading) return;
    try {
      final path = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.doctorAddPhoto.tr,
      ).catchError((_) => null);
      if (path == null || path.isEmpty) return;

      setState(() => _isUploading = true);

      final file = File(path);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 75,
      );
      await _businessController.saveBusinessImages(
        compressed?.path ?? path,
        _businessController,
      );
    } catch (_) {
      commonSnackBar(message: AppStrings.genericImageUploadFailed.tr);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.gallery.tr,
                  fontWeight: FontWeight.w700,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                ),
              ),
              InkWell(
                onTap: _addPhoto,
                child: CustomText(
                  AppStrings.doctorAddPhoto.tr,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.small,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Obx(() {
            final photos = (_businessController
                        .businessProfileDetails.value?.data?.livePhotos ??
                    const <String>[])
                .where((p) => p.trim().isNotEmpty)
                .toList();
            if (photos.isEmpty) return _empty();
            return _grid(photos);
          }),
          if (_isUploading) ...[
            SizedBox(height: SizeConfig.size10),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return InkWell(
      onTap: _addPhoto,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 26, color: AppColors.primaryColor),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              AppStrings.doctorGalleryEmpty.tr,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Up to six thumbnails; the sixth carries a `+n` overlay when there are
  /// more, and opens the full-screen viewer with the complete list.
  Widget _grid(List<String> photos) {
    const int maxTiles = 6;
    final display =
        photos.length > maxTiles ? photos.sublist(0, maxTiles) : photos;
    final extra = photos.length > maxTiles ? photos.length - maxTiles : 0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: display.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final isLast = index == maxTiles - 1 && extra > 0;
        return GestureDetector(
          onTap: () => Get.to(
            () => ImageViewScreen(
              appBarTitle: AppStrings.gallery.tr,
              subTitle: AppStrings.gallery.tr,
              imageUrls: photos,
              initialIndex: index,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: display[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                if (isLast)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: CustomText(
                      '+$extra',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
