import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/lost_media_recovery.dart';
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

    // The chooser answers which source was picked and closes immediately; the
    // pick and crop then run with the dialog already gone.
    //
    // It used to stay open across that work and pop with the finished path.
    // That is unsafe: Navigator.pop targets the topmost route of the nearest
    // navigator, not the route owning the context passed to it, and
    // `dialogContext.mounted` only says the dialog still exists — not that it
    // is on top. Croppy's editor is still on the stack when its future
    // completes, because it holds local history entries, so the pop landed on
    // a Route<CropImageResult?> carrying a String and LocalHistoryRoute.didPop
    // threw "type 'String' is not a subtype of type 'CropImageResult?'".
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) {
        return _PickerDialog(
          title: title,
          showCamera: cameraOn,
          showGallery: galleryOn,
          // Safe to pop by context here: nothing has been pushed over the
          // dialog at this point, so it is still the topmost route.
          onCamera: () => Navigator.pop(dialogContext, ImageSource.camera),
          onGallery: () => Navigator.pop(dialogContext, ImageSource.gallery),
        );
      },
    );

    if (source == null || !context.mounted) return null;

    return source == ImageSource.camera
        ? pickFromCamera(
            context,
            cropAspectRatio: cropAspectRatio,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
          )
        : pickFromGallery(
            context,
            cropAspectRatio: cropAspectRatio,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
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

    // Same shape as pickSinglePhoto — see the note there for why the chooser
    // closes before the pick runs rather than popping with the result.
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) {
        return _PickerDialog(
          title: title,
          showCamera: cameraOn,
          showGallery: galleryOn,
          onCamera: () => Navigator.pop(dialogContext, ImageSource.camera),
          onGallery: () => Navigator.pop(dialogContext, ImageSource.gallery),
        );
      },
    );

    if (source == null || !context.mounted) return null;

    return source == ImageSource.camera
        ? pickMultipleFromCamera(
            context,
            cropAspectRatio: cropAspectRatio,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
          )
        : pickMultipleFromGallery(
            context,
            maxImages: maxImages,
            cropAspectRatio: cropAspectRatio,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
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
    final picker = SafeImagePicker();
    final List<XFile> pickedFiles;
    try {
      // `limit` caps the selection in the system picker itself. Without it the
      // user can select an unbounded number of photos and only find out
      // afterwards — and every extra one still had to be decoded and processed
      // below, which is how a 60-photo selection turned into an OOM.
      pickedFiles = await picker.pickMultiImage(
        limit: (maxImages != null && maxImages > 1) ? maxImages : null,
      );
    } on PlatformException catch (e) {
      _handlePickerError(e, source: ImageSource.gallery);
      return null;
    } catch (e) {
      _handleUnexpectedError(e);
      return null;
    }

    if (pickedFiles.isEmpty) return null;

    // Older devices and some OEM pickers ignore `limit`, so the cap is still
    // enforced here.
    final limited = (maxImages != null)
        ? pickedFiles.take(maxImages).toList()
        : pickedFiles;

    if (maxImages != null && pickedFiles.length > maxImages) {
      commonSnackBar(
          message: 'You can select up to $maxImages images only.');
    }

    final results = <String>[];
    for (int i = 0; i < limited.length; i++) {
      if (!context.mounted) break;
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

  /// Pops [dialogContext] with whatever [run] produced — including when it
  /// throws.
  ///
  /// The chooser's buttons drive an async pick whose result is delivered by
  /// popping the dialog. Any throw in between (a failed compress on an OEM
  /// image format, a cropper failure, a missing temp dir) used to escape as an
  /// unhandled async error, so the pop never ran: the dialog stayed on screen
  /// with no way out and the awaiting caller never resolved. Containing the
  /// error here means the chooser always closes and the caller always gets an
  /// answer, even if that answer is "nothing".

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

    // Captured BEFORE the push, and used instead of letting the cropper pop
    // itself. See [_popCropper] — `shouldPopAfterCrop` is off for the same
    // reason.
    final cropNavigator = Navigator.of(context);
    CropImageResult? cropResult;

    // Always open the cropper fresh on the actual image (no `initialData`).
    // A remembered crop is keyed only by `page`, which is not unique to an
    // image, so restoring it carried a previous image's framing over and
    // made the crop appear "reset". Starting fresh every time avoids that.
    //
    // Cancelling still returns cleanly: the cropper's own Cancel button uses
    // `Navigator.maybePop`, which is already safe.
    await showCupertinoImageCropper(
      context,
      locale: const Locale('en', 'US'),
      imageProvider: fileImage,
      heroTag: 'photo-$page',
      enabledTransformations: const [
        Transformation.resize,
        Transformation.panAndScale,
      ],
      shouldPopAfterCrop: false,
      postProcessFn: (result) async {
        cropResult = result;
        _popCropper(cropNavigator, result);
        return result;
      },
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

    // Drop the full-resolution decode from Flutter's image cache now that the
    // cropper is done with it. Without this each picked photo leaves ~10 MB+ of
    // decoded bitmap resident, and a multi-image selection walks straight into
    // an OutOfMemoryError on a low-RAM device.
    _evict(fileImage);

    final result = cropResult;
    if (result == null) return ''; // user cancelled the cropper

    final savedFile = await _saveUiImageToFile(result.uiImage, page);
    return savedFile?.path ?? '';
  }

  /// Closes the cropper page ourselves, instead of letting it close itself.
  ///
  /// `showCupertinoImageCropper(shouldPopAfterCrop: true)` ends with a bare
  /// `Navigator.of(context).pop(result)` inside the package (unchanged as of
  /// croppy 1.5.3, so upgrading is not the answer). Cropping a large photo
  /// takes long enough for the navigator underneath to be emptied in the
  /// meantime — a deep link, a logout, an incoming call unwinding the stack —
  /// and `pop` on a navigator with no present route throws `Bad state: No
  /// element` out of `_history.lastWhere`, from a callback nothing can catch.
  /// The widget's own `context.mounted` check does not cover it: the element
  /// is still alive while its route animates away.
  ///
  /// [NavigatorState.canPop] is precisely the missing guard — it reports false
  /// for the empty-history case that makes `pop` throw. Nothing to pop also
  /// means nothing to return to, so skipping is the correct outcome, not a
  /// silent failure.
  ///
  /// `canPop` is not enough on its own, though: `pop` closes whatever is on
  /// TOP, not the cropper. If the cropper is already gone (backed out while
  /// the crop was processing) or something was pushed over it, the result
  /// lands on another route, and a typed one rejects it —
  ///   type 'CropImageResult' is not a subtype of type 'String?' of 'result'
  /// So pop only when the top route is the cropper, which croppy pushes as a
  /// `Route<CropImageResult?>`.
  static void _popCropper(NavigatorState navigator, CropImageResult result) {
    if (!navigator.mounted || !navigator.canPop()) return;
    // popUntil with a predicate that accepts the first route it sees reads
    // the top route without popping anything; Navigator has no getter for it.
    Route<dynamic>? top;
    navigator.popUntil((route) {
      top = route;
      return true;
    });
    if (top is! Route<CropImageResult?>) return;
    navigator.pop(result);
  }

  /// Removes [provider] from the image cache, live entries included.
  static void _evict(ImageProvider provider) {
    try {
      PaintingBinding.instance.imageCache.evict(provider);
    } catch (_) {
      // Cache eviction is an optimisation; never let it break a pick.
    }
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
    final picker = SafeImagePicker();
    final XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: source);
    } on PlatformException catch (e) {
      _handlePickerError(e, source: source);
      return null;
    } catch (e) {
      _handleUnexpectedError(e);
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

  /// Last-resort handler for anything that is not a `PlatformException` —
  /// compression failures on unusual OEM image formats, cropper errors, a
  /// missing temp directory. These used to escape as unhandled async errors
  /// and strand the chooser dialog on screen.
  static void _handleUnexpectedError(Object e) {
    // ignore: avoid_print
    print('Photo picker failed: $e');
    commonSnackBar(message: 'Could not use that photo. Please try again.');
  }

  /// Persists the cropper's output as JPEG.
  ///
  /// `ui.Image.toByteData` can only emit PNG, and writing that PNG straight to
  /// disk was throwing away the JPEG compression applied moments earlier — a
  /// photo re-encoded losslessly lands at 4-8 MB, so every upload was several
  /// times larger than intended and the bytes stayed resident meanwhile. The
  /// PNG is therefore transcoded to JPEG in memory and only the JPEG is
  /// written. The source [ui.Image] is disposed as soon as its bytes are out,
  /// releasing the native bitmap instead of waiting on the GC.
  static Future<File?> _saveUiImageToFile(
    ui.Image image,
    int page, {
    int quality = 85,
  }) async {
    try {
      final ByteData? byteData;
      try {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        try {
          image.dispose();
        } catch (_) {
          // Already disposed by the cropper — nothing to release.
        }
      }
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      Uint8List outBytes;
      String extension;
      try {
        outBytes = await FlutterImageCompress.compressWithList(
          pngBytes,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        extension = 'jpg';
      } catch (_) {
        // Transcode unavailable for this input on this device; the PNG is a
        // correct (if larger) result, so fall back rather than losing the crop.
        outBytes = pngBytes;
        extension = 'png';
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${tempDir.path}/cropped_image_$page$timestamp.$extension';

      final file = File(filePath);
      await file.writeAsBytes(outBytes);
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
