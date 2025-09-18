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
  static final Map<int, CroppableImageData?> _data = {};

  static Future<String?> _handlePick(
      BuildContext context, {
        required ImageSource source,
        CropAspectRatio? cropAspectRatio,
      }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return null;

    final originalFile = File(pickedFile.path);
    final originalSize = await originalFile.length();

    final compressedFile = await compressImage(originalFile);
    final finalImage = compressedFile ?? originalFile;

    final newSize = await finalImage.length();
    _printCompressionStats(originalSize, newSize, compressedFile != null);

    final croppedPath = await cropImage(
      context,
      finalImage.path,
      cropAspectRatio: cropAspectRatio,
    );
    return croppedPath;
  }

  /// Camera picker
  static Future<String?> pickFromCamera(BuildContext context,
      {CropAspectRatio? cropAspectRatio}) {
    return _handlePick(context,
        source: ImageSource.camera, cropAspectRatio: cropAspectRatio);
  }

  /// Gallery picker
  static Future<String?> pickFromGallery(BuildContext context,
      {CropAspectRatio? cropAspectRatio}) {
    return _handlePick(context,
        source: ImageSource.gallery, cropAspectRatio: cropAspectRatio);
  }

  /// Show dialog for logo/photo picker
  static Future showLogoDialog(
      BuildContext context,
      String title, {
        bool? isOnlyCamera = true,
        bool? isGallery = true,
        CropAspectRatio? cropAspectRatio,
      }) async {
    final appLocalizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DialogHeader(title: title),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isOnlyCamera ?? false)
                          Expanded(
                            child: OptionButton(
                              iconPath: AppIconAssets.camera_sky,
                              label: appLocalizations?.takeOne ?? "",
                              onTap: () async {
                                final path = await pickFromCamera(context,
                                    cropAspectRatio: cropAspectRatio);
                                Navigator.pop(context, path);
                              },
                            ),
                          ),
                        if (isGallery ?? false)
                          Expanded(
                            child: OptionButton(
                              iconPath: AppIconAssets.gallery_sky,
                              label:
                              appLocalizations?.selectFromGallery ?? "",
                              onTap: () async {
                                final path = await pickFromGallery(context,
                                    cropAspectRatio: cropAspectRatio);
                                Navigator.pop(context, path);
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
  }

  /// Show dialog for video picker
  static Future showVideoDialog(
      BuildContext context,
      String title, {
        required VoidCallback onPickFromCamera,
        required VoidCallback onPickFromGallery,
      }) async {
    final appLocalizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DialogHeader(title: title),
                  Padding(
                    padding: EdgeInsets.all(SizeConfig.size20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OptionButton(
                            iconPath: AppIconAssets.camera_sky,
                            label: appLocalizations?.takeOne ?? "",
                            onTap: onPickFromCamera,
                          ),
                        ),
                        Expanded(
                          child: OptionButton(
                            iconPath: AppIconAssets.gallery_sky,
                            label: appLocalizations?.selectFromGallery ?? "",
                            onTap: onPickFromGallery,
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
  }

  /// Cropper
  static Future<String> cropImage(BuildContext context, String filePath,
      {CropAspectRatio? cropAspectRatio}) async {
    final imageFile = File(filePath);
    final fileImage = FileImage(imageFile);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await precacheImage(fileImage, context);

    Navigator.of(context).pop(); // close loading

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
      allowedAspectRatios: [
        cropAspectRatio ?? CropAspectRatio(width: 10, height: 10),
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

  /// Save image
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

  /// Compression
  static Future<File?> compressImage(File rawFile, {int quality = 70}) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      rawFile.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1080,
      minHeight: 1080,
    );

    return result != null ? File(result.path) : null;
  }

  /// Print compression stats
  static void _printCompressionStats(
      int originalSize, int newSize, bool attempted) {
    if (!attempted) {
      print("❌ Compression failed or skipped (using original image)");
      return;
    }
    if (newSize < originalSize) {
      final reduction =
      ((originalSize - newSize) / originalSize * 100).toStringAsFixed(2);
      print(
          "✅ Image compressed successfully: $originalSize → $newSize bytes (Reduced $reduction%)");
    } else {
      print("⚠️ Compression attempted but size did not reduce");
    }
  }
}

/// Dialog header widget
class DialogHeader extends StatelessWidget {
  final String title;

  const DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.all(1.0),
      child: Row(
        children: [
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}

/// Option button widget
class OptionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const OptionButton({
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
