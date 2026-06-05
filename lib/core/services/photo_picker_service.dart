import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Single entry point for picking photos in the app.
class PhotoPickerService {
  // Per-page snapshot of the last crop state so re-opening a picker on
  // the same gallery slot restores the previous crop framing.
  static final Map<int, CroppableImageData?> _cropMemory = {};

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API — SINGLE PHOTO
  // ─────────────────────────────────────────────────────────────

  /// Show the camera/gallery chooser and return ONE picked + cropped
  /// photo path. When only one source is enabled, the chooser is
  /// skipped and the user lands directly on that source.
  static Future<String?> pickSinglePhoto(
    BuildContext context,
    String title, {
    bool? isOnlyCamera = true,
    bool? isGallery = true,
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) async {
    final cameraOn = isOnlyCamera ?? true;
    final galleryOn = isGallery ?? true;

    // Skip the chooser when only one source is enabled.
    if (cameraOn && !galleryOn) {
      return pickFromCamera(
        context,
        cropAspectRatio: cropAspectRatio,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
    }
    if (galleryOn && !cameraOn) {
      return pickFromGallery(
        context,
        cropAspectRatio: cropAspectRatio,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
    }

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _PickerDialog(
          title: title,
          showCamera: cameraOn,
          showGallery: galleryOn,
          onCamera: () async {
            final path = await pickFromCamera(
              dialogContext,
              cropAspectRatio: cropAspectRatio,
              quality: quality,
              minWidth: minWidth,
              minHeight: minHeight,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, path);
          },
          onGallery: () async {
            final path = await pickFromGallery(
              dialogContext,
              cropAspectRatio: cropAspectRatio,
              quality: quality,
              minWidth: minWidth,
              minHeight: minHeight,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, path);
          },
        );
      },
    );
  }

  /// Open the camera directly (no chooser dialog) for one photo.
  static Future<String?> pickFromCamera(
    BuildContext context, {
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) {
    return _pickAndProcessSingle(
      context,
      source: ImageSource.camera,
      cropAspectRatio: cropAspectRatio,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );
  }

  /// Open the gallery directly (no chooser dialog) for one photo.
  static Future<String?> pickFromGallery(
    BuildContext context, {
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) {
    return _pickAndProcessSingle(
      context,
      source: ImageSource.gallery,
      cropAspectRatio: cropAspectRatio,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API — MULTIPLE PHOTOS
  // ─────────────────────────────────────────────────────────────

  /// Show the camera/gallery chooser and return N picked + cropped
  /// photo paths. Camera path returns at most one; gallery supports
  /// native multi-select capped by [maxImages].
  static Future<List<String>?> pickMultiplePhotos(
    BuildContext context,
    String title, {
    bool? isOnlyCamera = true,
    bool? isGallery = true,
    int? maxImages,
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) async {
    final cameraOn = isOnlyCamera ?? true;
    final galleryOn = isGallery ?? true;

    if (cameraOn && !galleryOn) {
      return pickMultipleFromCamera(
        context,
        cropAspectRatio: cropAspectRatio,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
    }
    if (galleryOn && !cameraOn) {
      return pickMultipleFromGallery(
        context,
        maxImages: maxImages,
        cropAspectRatio: cropAspectRatio,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
    }

    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return _PickerDialog(
          title: title,
          showCamera: cameraOn,
          showGallery: galleryOn,
          onCamera: () async {
            final paths = await pickMultipleFromCamera(
              dialogContext,
              cropAspectRatio: cropAspectRatio,
              quality: quality,
              minWidth: minWidth,
              minHeight: minHeight,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, paths);
          },
          onGallery: () async {
            final paths = await pickMultipleFromGallery(
              dialogContext,
              maxImages: maxImages,
              cropAspectRatio: cropAspectRatio,
              quality: quality,
              minWidth: minWidth,
              minHeight: minHeight,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, paths);
          },
        );
      },
    );
  }

  /// Single-shot camera capture wrapped in a list (so multi-photo
  /// callers can keep a uniform `List<String>?` return type).
  static Future<List<String>?> pickMultipleFromCamera(
    BuildContext context, {
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) async {
    final path = await _pickAndProcessSingle(
      context,
      source: ImageSource.camera,
      cropAspectRatio: cropAspectRatio,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );
    return path != null ? [path] : null;
  }

  /// Native gallery multi-select. Respects [maxImages] and surfaces a
  /// snackbar when the user picks more than the cap.
  static Future<List<String>?> pickMultipleFromGallery(
    BuildContext context, {
    int? maxImages,
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles;
    try {
      pickedFiles = await picker.pickMultiImage();
    } on PlatformException catch (e) {
      _handlePickerError(e, source: ImageSource.gallery);
      return null;
    }

    if (pickedFiles.isEmpty) return null;

    final limited = (maxImages != null)
        ? pickedFiles.take(maxImages).toList()
        : pickedFiles;

    if (maxImages != null && pickedFiles.length > maxImages) {
      commonSnackBar(
          message: 'You can select up to $maxImages images only.');
    }

    final results = <String>[];
    for (int i = 0; i < limited.length; i++) {
      final processed = await _processImage(
        context,
        File(limited[i].path),
        cropAspectRatio: cropAspectRatio,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        page: i,
      );
      if (processed != null) results.add(processed);
    }
    return results;
  }

  /// Generic source-chooser dialog with caller-supplied handlers —
  /// used for flows where the picker itself isn't an image (e.g. video
  /// recording vs. gallery video). The service doesn't run the
  /// underlying pickers, only paints the same chooser UI as the photo
  /// flows so the surface stays visually consistent.
  static Future<void> showSourceChooserDialog(
    BuildContext context,
    String title, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _PickerDialog(
        title: title,
        showCamera: true,
        showGallery: true,
        onCamera: onCamera,
        onGallery: onGallery,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC UTILITIES — exposed because non-picker code paths
  // (post upload, reel upload) compress/crop standalone files.
  // ─────────────────────────────────────────────────────────────

  /// Compress a raw image file via JPEG. Returns null when the encoder
  /// declines (very small or already-compressed sources).
  static Future<File?> compressImage(
    File rawFile, {
    int quality = 70,
    int? minWidth,
    int? minHeight,
  }) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      rawFile.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minWidth ?? 1920,
      minHeight: minHeight ?? 1080,
    );
    return result != null ? File(result.path) : null;
  }

  /// Open the in-app cropper on [filePath] and return the saved
  /// cropped path. Empty string is returned when the user cancels.
  static Future<String> cropImage(
    BuildContext context,
    String filePath, {
    CropAspectRatio? cropAspectRatio,
    int page = 0,
  }) async {
    final fileImage = FileImage(File(filePath));

    // Pre-decode the image so the cropper opens without a blank frame.
    // Dismiss the spinner via the root navigator (and a `finally`) so we
    // never pop the wrong route or leave it stuck if precache throws.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await precacheImage(fileImage, context);
    } finally {
      if (rootNavigator.canPop()) rootNavigator.pop();
    }

    if (!context.mounted) return '';

    // Await the cropper's own result. With `shouldPopAfterCrop` the cropper
    // pops itself with the CropImageResult on submit, or with null when the
    // user backs out — so cancellation returns cleanly instead of hanging,
    // and a successful crop always reaches us here.
    final result = await showCupertinoImageCropper(
      context,
      locale: const Locale('en', 'US'),
      imageProvider: fileImage,
      heroTag: 'photo-$page',
      initialData: _cropMemory[page],
      enabledTransformations: const [
        Transformation.resize,
        Transformation.panAndScale,
      ],
      shouldPopAfterCrop: true,
      allowedAspectRatios: (cropAspectRatio != null)
          ? [cropAspectRatio]
          : const [
              CropAspectRatio(width: 1, height: 1), // Square
              CropAspectRatio(width: 2, height: 3), // Mobile portrait
              CropAspectRatio(width: 3, height: 4), // Common portrait
            ],
      showLoadingIndicatorOnSubmit: true,
      themeData: const CupertinoThemeData(),
    );

    if (result == null) return ''; // user cancelled the cropper

    // Remember the framing so re-opening this slot restores the crop.
    _cropMemory[page] = result.transformationsData;

    final savedFile = await _saveUiImageToFile(result.uiImage, page);
    return savedFile?.path ?? '';
  }

  // ─────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────

  static Future<String?> _pickAndProcessSingle(
    BuildContext context, {
    required ImageSource source,
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
  }) async {
    final picker = ImagePicker();
    final XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: source);

    } on PlatformException catch (e) {

      _handlePickerError(e, source: source);

      return null;
    }

    if (pickedFile == null) return null;

    if (!context.mounted) return null;

    return _processImage(
      context,
      File(pickedFile.path),
      cropAspectRatio: cropAspectRatio,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      page: 0,
    );
  }

  static Future<String?> _processImage(
    BuildContext context,
    File originalFile, {
    CropAspectRatio? cropAspectRatio,
    int? quality,
    int? minWidth,
    int? minHeight,
    required int page,
  }) async {
    final originalSize = await originalFile.length();

    final compressedFile = await compressImage(
      originalFile,
      quality: quality ?? 70,
      minWidth: minWidth,
      minHeight: minHeight,
    );

    final finalImage = compressedFile ?? originalFile;
    final newSize = await finalImage.length();
    _logCompression(originalSize, newSize, compressedFile != null);

    if (!context.mounted) return null;

    final croppedPath = await cropImage(
      context,
      finalImage.path,
      cropAspectRatio: cropAspectRatio,
      page: page,
    );

    return croppedPath.isEmpty ? null : croppedPath;
  }

  /// Handles `camera_access_denied` / `photo_access_denied` and any
  /// other `PlatformException` from the native picker. Surfaces a
  /// human-readable snackbar so the picker failure doesn't crash up
  /// to the engine.
  static void _handlePickerError(
    PlatformException e, {
    required ImageSource source,
  }) {
    final code = e.code;
    if (code == 'camera_access_denied' || code == 'photo_access_denied') {
      final isCamera = source == ImageSource.camera;
      commonSnackBar(
        message: isCamera
            ? 'Camera access is blocked. Enable it in Settings to take a photo.'
            : 'Photos access is blocked. Enable it in Settings to pick an image.',
      );
    } else {
      commonSnackBar(message: e.message ?? 'Could not open the picker.');
    }
  }

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
      // ignore: avoid_print
      print('Error saving cropped image: $e');
      return null;
    }
  }

  static void _logCompression(int originalSize, int newSize, bool attempted) {
    if (!attempted) {
      // ignore: avoid_print
      print('❌ Compression failed or skipped (using original image)');
      return;
    }
    if (newSize < originalSize) {
      final reductionPercent =
          ((originalSize - newSize) / originalSize * 100).toStringAsFixed(2);
      // ignore: avoid_print
      print('✅ Image compressed: '
          '${formatBytesToMB(originalSize)} MB → '
          '${formatBytesToMB(newSize)} MB '
          '(Reduced $reductionPercent%)');
    } else {
      // ignore: avoid_print
      print('⚠️ Compression attempted but size did not reduce');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG UI — private to the service
// ─────────────────────────────────────────────────────────────

class _PickerDialog extends StatelessWidget {
  final String title;
  final bool showCamera;
  final bool showGallery;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickerDialog({
    required this.title,
    required this.showCamera,
    required this.showGallery,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(title: title),
              Padding(
                padding: EdgeInsets.all(SizeConfig.size20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (showCamera)
                      Expanded(
                        child: _OptionButton(
                          iconPath: AppIconAssets.camera_sky,
                          label: AppStrings.takeFromCamera,
                          onTap: onCamera,
                        ),
                      ),
                    if (showGallery)
                      Expanded(
                        child: _OptionButton(
                          iconPath: AppIconAssets.gallery_sky,
                          label: AppStrings.selectFromGallery,
                          onTap: onGallery,
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
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.all(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
