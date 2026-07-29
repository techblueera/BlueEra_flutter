import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';

/// "Cover Photo" card with the Edit pill from the design.
///
/// The cover lives on the BUSINESS record (user-service), not on the doctor
/// profile — so this goes through `updateBusinessProfileDetails`, exactly like
/// every other business cover editor in the app.
class DoctorCoverPhotoCard extends StatefulWidget {
  const DoctorCoverPhotoCard({super.key});

  @override
  State<DoctorCoverPhotoCard> createState() => _DoctorCoverPhotoCardState();
}

class _DoctorCoverPhotoCardState extends State<DoctorCoverPhotoCard> {
  final _businessController =
      getOrPut(() => ViewBusinessDetailsController(), permanent: true);
  bool _isUploading = false;

  Future<void> _editCover() async {
    if (_isUploading) return;
    try {
      final newPath = await PhotoPickerService.pickSinglePhoto(
        context,
        AppStrings.editCoverPicture.tr,
        cropAspectRatio: CropAspectRatio(width: 3, height: 2),
      ).catchError((_) => null);
      if (newPath == null || newPath.isEmpty) return;

      setState(() => _isUploading = true);

      final file = File(newPath);
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 75,
      );
      final dataImage =
          await multiPartImage(imagePath: compressed?.path ?? newPath);
      if (dataImage == null) {
        commonSnackBar(message: AppStrings.imageProcessingFailed.tr);
        return;
      }

      final details = _businessController.businessProfileDetails.value?.data;
      await _businessController.updateBusinessProfileDetails({
        ApiKeys.businessId: businessId,
        ApiKeys.business_name: details?.businessName,
        ApiKeys.coverimg: dataImage,
      });
    } catch (_) {
      commonSnackBar(message: AppStrings.updatePictureFailed.tr);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final cover = _businessController.coverImage?.value ?? '';
            return GestureDetector(
              onTap: _editCover,
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover.isEmpty)
                      _empty()
                    // A freshly picked file is set on `coverImage` optimistically
                    // before the upload finishes, so it is a local path until
                    // the profile refetch swaps in the remote URL.
                    else if (cover.startsWith('http'))
                      CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => _empty(),
                      )
                    else
                      Image.file(File(cover), fit: BoxFit.cover),
                    if (_isUploading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.doctorCoverPhoto.tr,
                    fontWeight: FontWeight.w700,
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                  ),
                ),
                InkWell(
                  onTap: _editCover,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                      vertical: SizeConfig.size4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 13, color: AppColors.primaryColor),
                        SizedBox(width: SizeConfig.size4),
                        CustomText(
                          AppStrings.edit.tr,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      color: const Color(0xFFF7FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 40, color: AppColors.primaryColor),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.doctorAddCoverPhoto.tr,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}
