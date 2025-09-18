import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class SelectProductImageDialog {
  static final Map<int, CroppableImageData?> _data = {};

  /// Show dialog for logo/photo picker
  static Future<List<String>?> showLogoDialog(
    BuildContext context,
    String title, {
    bool? isOnlyCamera = true,
    bool? isGallery = true,
    CropAspectRatio? cropAspectRatio,
  }) async {
    final appLocalizations = AppLocalizations.of(context);

    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                                final paths = await pickFromCamera(
                                  context,
                                  cropAspectRatio: cropAspectRatio,
                                );
                                Navigator.pop(context, paths);
                              },
                            ),
                          ),
                        if (isGallery ?? false)
                          Expanded(
                            child: OptionButton(
                              iconPath: AppIconAssets.gallery_sky,
                              label: appLocalizations?.selectFromGallery ?? "",
                              onTap: () async {
                                final paths = await pickFromGallery(
                                  context,
                                  cropAspectRatio: cropAspectRatio,
                                );
                                Navigator.pop(context, paths);
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

  /// Camera picker
  static Future<List<String>?> pickFromCamera(
    BuildContext context, {
    CropAspectRatio? cropAspectRatio,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    final processed = await _processImage(
      context,
      file,
      cropAspectRatio: cropAspectRatio,
      page: 0,
    );
    return processed != null ? [processed] : null;
  }

  /// Gallery picker (multi-select)
  static Future<List<String>?> pickFromGallery(
    BuildContext context, {
    CropAspectRatio? cropAspectRatio,
  }) async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return null;

    List<String> results = [];
    for (int i = 0; i < pickedFiles.length; i++) {
      final file = File(pickedFiles[i].path);
      final processed = await _processImage(
        context,
        file,
        cropAspectRatio: cropAspectRatio,
        page: i,
      );
      if (processed != null) {
        results.add(processed);
      }
    }
    return results;
  }

  /// Process (compress + crop)
  static Future<String?> _processImage(
    BuildContext context,
    File originalFile, {
    CropAspectRatio? cropAspectRatio,
    required int page,
  }) async {
    final originalSize = await originalFile.length();
    final compressedFile = await compressImage(originalFile);
    final finalImage = compressedFile ?? originalFile;

    final newSize = await finalImage.length();
    _printCompressionStats(originalSize, newSize, compressedFile != null);

    final croppedPath = await cropImage(
      context,
      finalImage.path,
      cropAspectRatio: cropAspectRatio,
      page: page,
    );
    return croppedPath;
  }

  /// Cropper
  static Future<String?> cropImage(
    BuildContext context,
    String filePath, {
    CropAspectRatio? cropAspectRatio,
    required int page,
  }) async {
    final imageFile = File(filePath);
    final fileImage = FileImage(imageFile);

// show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await precacheImage(fileImage, context);
    Navigator.of(context).pop();

    final completer = Completer<String>();

    showCupertinoImageCropper(
      context,
      locale: const Locale('en', 'US'),
      imageProvider: fileImage,
      heroTag: 'image-$page',
      initialData: _data[page],
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
        final savedFile = await _saveUiImageToFile(result.uiImage, page);
        completer.complete(savedFile?.path);
        return result;
      },
      themeData: const CupertinoThemeData(),
    );

    return completer.future;
  }

  /// Save image to file
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

  /// Compression stats
  static void _printCompressionStats(
    int originalSize,
    int newSize,
    bool attempted,
  ) {
    if (!attempted) {
      print("❌ Compression failed or skipped (using original image)");
      return;
    }
    if (newSize < originalSize) {
      final reduction =
          ((originalSize - newSize) / originalSize * 100).toStringAsFixed(2);
      print(
        "✅ Image compressed successfully: $originalSize → $newSize bytes (Reduced $reduction%)",
      );
    } else {
      print("⚠️ Compression attempted but size did not reduce");
    }
  }
}
