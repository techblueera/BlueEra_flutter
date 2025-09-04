import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SelectProfilePictureDialog {
  static Map<int, CroppableImageData?> _data = {};

  static Future<File?> pickFile(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // if (!isAllowedImageExtension(pickedFile.path)) {
      //   commonSnackBar(message: 'Only JPG, JPEG, and PNG files are allowed.');
      //   return null;
      // }
      return File(pickedFile.path);
    }
    return null;
  }


  static Future showLogoDialog(BuildContext context, String title, {bool? isOnlyCamera = true, bool? isGallery = true, bool? isCircleCrop = true}) async {
    final appLocalizations = AppLocalizations.of(context);

    final result = await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: AppColors.primaryColor,
                    padding: const EdgeInsets.all(1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Spacer(),
                        // SizedBox(width: SizeConfig.size50,),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size20,
                              horizontal: SizeConfig.size20,
                            ),
                            child: CustomText(
                              title,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              color: Colors.white,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Spacer(),

                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isOnlyCamera ?? false)
                          Expanded(
                            child: _OptionButton(
                              iconPath: AppIconAssets.camera_sky,
                              label: appLocalizations?.takeOne ?? "",
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                                if (pickedFile != null) {
                                  // if (!isAllowedImageExtension(pickedFile.path)) {
                                  //   commonSnackBar(message: 'Only JPG, JPEG, and PNG files are allowed.');
                                  //   return;
                                  // }

                                  Future.delayed(Duration.zero, () async {
                                    final croppedPath = await cropImage(context, pickedFile.path);
                                    Navigator.pop(context, croppedPath);
                                    // Navigator.pop(context, pickedFile.path);
                                  });
                                }
                              },
                            ),
                          ),
                        if (isGallery ?? false)
                          Expanded(
                            child: _OptionButton(
                              iconPath: AppIconAssets.gallery_sky,
                              label: appLocalizations?.selectFromGallery ?? "",
                              onTap: () async {

                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                                if (pickedFile != null) {
                                  // if (!isAllowedImageExtension(pickedFile.path)) {
                                  //   commonSnackBar(message: 'Only JPG, JPEG, and PNG files are allowed.');
                                  //   return;
                                  // }

                                  Future.delayed(Duration.zero, () async {
                                    final croppedPath = await cropImage(context, pickedFile.path);
                                    Navigator.pop(context, croppedPath);
                                    // Navigator.pop(context, pickedFile.path);
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }

  static Future showVideoDialog(BuildContext context, String title, {required VoidCallback onPickFromCamera, required VoidCallback onPickFromGallery}) async {
    final appLocalizations = AppLocalizations.of(context);

    final result = await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: AppColors.primaryColor,
                    padding: const EdgeInsets.all(1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Spacer(),
                        // SizedBox(width: SizeConfig.size50,),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size20,
                              horizontal: SizeConfig.size20,
                            ),
                            child: CustomText(
                              title,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              color: Colors.white,
                              fontSize: SizeConfig.large,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Spacer(),

                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          Expanded(
                            child: _OptionButton(
                              iconPath: AppIconAssets.camera_sky,
                              label: appLocalizations?.takeOne ?? "",
                              onTap: () => onPickFromCamera(),
                            ),
                          ),
                          Expanded(
                            child: _OptionButton(
                              iconPath: AppIconAssets.gallery_sky,
                              label: appLocalizations?.selectFromGallery ?? "",
                              onTap: () => onPickFromGallery(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: SizeConfig.size10),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }

  ///New Cropper
  static Future<String> cropImage(BuildContext context, String filePath) async {
    final imageFile = File(filePath);
    final fileImage = FileImage(imageFile);

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Preload the image while loading indicator is up
    await precacheImage(fileImage, context);

    // Remove loading dialog before showing cropper
    Navigator.of(context).pop();

    final completer = Completer<String>();

    showCupertinoImageCropper(
      context,
      locale: const Locale('en', 'US'),
      imageProvider: fileImage,
      heroTag: 'video-0',
      initialData: _data[0],
      enabledTransformations: [
        Transformation.resize,
        Transformation.panAndScale,
      ],
      shouldPopAfterCrop: true,
      allowedAspectRatios: const [
        // CropAspectRatio(width: 1, height: 1),
        // CropAspectRatio(width: 4, height: 3),
        // CropAspectRatio(width: 16, height: 9),
        CropAspectRatio(width: 10, height: 10),
      ],
      showLoadingIndicatorOnSubmit: true,
      postProcessFn: (result) async {
        final savedFile = await _saveUiImageToFile(result.uiImage, 0);
        completer.complete(savedFile?.path ?? "");
        return result;
      },
      themeData: CupertinoThemeData()
    );

    return completer.future;
  }

  /// Save a ui.Image as a PNG file to temporary storage.
  static Future<File?> _saveUiImageToFile(ui.Image image, int page) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/cropped_image_$page$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      print('Error saving cropped image: $e');
      return null;
    }
  }

  Future<File?> compressImage(File rawFile, {int quality = 85}) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      rawFile.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1080,   // optional down-scale
      minHeight: 1080,
    );

    return result != null ? File(result.path) : null;
  }
}

class _OptionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 75,
            width: 75,
            padding: EdgeInsets.all(SizeConfig.size20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(SizeConfig.size10),
              border: Border.all(
                color: Colors.grey.shade400,
                width: SizeConfig.size1,
              ),
            ),
            child: LocalAssets(imagePath: iconPath),
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            label,
            textAlign: TextAlign.center,
            color: AppColors.primaryColor,
            fontSize: SizeConfig.small,
          ),
          SizedBox(height: SizeConfig.size20),
        ],
      ),
    );
  }
}
