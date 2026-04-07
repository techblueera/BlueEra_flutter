import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/qr_code/model/qr_design_model.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_card_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class QrFullScreenView extends StatelessWidget {
  final QrDesignModel design;
  final String userName;

  QrFullScreenView({
    super.key,
    required this.design,
    required this.userName,
  });

  final GlobalKey _repaintKey = GlobalKey();
  final RxBool _isSaving = false.obs;

  String get _qrData => 'https://emergency.blueera.ai/$userId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: CommonBackAppBar(title: AppStrings.myQrCode.tr,),
      // backgroundColor: AppColors.appBackgroundColor,
      // appBar: AppBar(
      //   backgroundColor: AppColors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: AppColors.black),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: const CustomText(
      //     'My QR Code',
      //     fontSize: 16,
      //     fontWeight: FontWeight.w600,
      //     color: AppColors.mainTextColor,
      //   ),
      //   centerTitle: false,
      // ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only the QR card sits inside the RepaintBoundary so that
                  // the captured image (used by Download / Share) contains
                  // ONLY the design — never the action buttons below it.
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: QrDesignCardWidget(
                        design: design,
                        qrData: _qrData,
                        userName: userName,
                        isThumbnail: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action bar lives OUTSIDE the RepaintBoundary so it
                  // never appears in the downloaded / shared image.
                  _buildActionBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: Obx(() => _buildButton(
                icon: AppIconAssets.download,
                label: _isSaving.value ? '${AppStrings.saving.tr}...' : AppStrings.download.tr,
                onTap: _isSaving.value ? null : _saveQrToGallery,
              )),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            icon:  AppIconAssets.send,
            label: AppStrings.share.tr,
            onTap: _shareQrLink,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.whiteE5, width: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(imagePath: icon,imgColor: AppColors.secondaryTextColor,width: 25,height: 25,),
            // Icon(icon, size: 20, color: AppColors.mainTextColor),
            const SizedBox(width: 8),
            CustomText(
              label,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing QR: $e");
      return null;
    }
  }

  /// Check gallery access using Gal (works on Android 13+ and iOS)
  Future<bool> _ensureGalleryAccess() async {
    // Gal.hasAccess handles Android 13+ granular permissions internally
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (hasAccess) return true;

    // Request access via Gal
    final granted = await Gal.requestAccess(toAlbum: true);
    if (granted) return true;

    // Permission denied — show dialog to open settings
    _showPermissionSettingsDialog();
    return false;
  }

  void _showPermissionSettingsDialog() {
    final context = Get.context;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(
          AppStrings.permissionRequired.tr,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          Platform.isIOS
              ? AppStrings.photoLibraryAccessNeeded.tr
              : AppStrings.storagePermissionNeeded.tr,
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: CustomText(
              AppStrings.cancel.tr,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: CustomText(
              AppStrings.openSettings.tr,
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQrToGallery() async {
    _isSaving.value = true;
    try {
      final hasAccess = await _ensureGalleryAccess();
      if (!hasAccess) return;

      final pngBytes = await _captureQrImage();
      if (pngBytes == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }

      // Write to temp file first, then save to gallery via Gal
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/qr_${design.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(filePath, album: 'BlueEra');

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }

      commonSnackBar(message: AppStrings.qrCodeSavedToGallery.tr);
    } catch (e) {
      debugPrint("Error saving QR: $e");
      commonSnackBar(message: AppStrings.failedToSaveQrCode.tr);
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _shareQrLink() async {
    try {
      await SharePlus.instance.share(ShareParams(
        text: "${AppStrings.checkMyEmergencyQrCode.tr}\n$_qrData",
      ));
    } catch (e) {
      debugPrint("Error sharing QR link: $e");
    }
  }
}
