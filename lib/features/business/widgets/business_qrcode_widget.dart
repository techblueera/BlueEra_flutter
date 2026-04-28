import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class BusinessQrCodeWidget extends StatefulWidget {
  final BusinessProfileDetails? data;

  /// Optional override; when null, the widget captures the QR card and
  /// saves it to the gallery via Gal under a "BlueEra" album.
  final VoidCallback? onDownload;

  /// Optional override; when null, the widget shares the deep link with
  /// the captured QR image attached.
  final VoidCallback? onShare;

  const BusinessQrCodeWidget({
    super.key,
    this.data,
    this.onDownload,
    this.onShare,
  });

  @override
  State<BusinessQrCodeWidget> createState() => _BusinessQrCodeWidgetState();
}

class _BusinessQrCodeWidgetState extends State<BusinessQrCodeWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  final RxBool _isSaving = false.obs;
  final RxBool _isSharing = false.obs;

  @override
  Widget build(BuildContext context) {

    final ownerUserId = widget.data?.userId ?? '';
    if (ownerUserId.isEmpty) return const SizedBox.shrink();
    final qrData = profileDeepLink(
      userId: ownerUserId,
      accountType: AppConstants.business,
    );

    return CustomFormCard(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // The capture surface — anything inside this RepaintBoundary
          // ends up in the saved/shared PNG. Action row stays outside
          // so the buttons never appear in the exported image.
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // ─── Business Name ───
                  CustomText(
                    widget.data?.businessName ?? '',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),

                  const SizedBox(height: 10),

                  // ─── Sub Category ───
                  BusinessCommonSubCategoryWidget(
                    label: widget.data?.subCategoryDetails?.name,
                  ),

                  const SizedBox(height: 20),

                  // ─── QR Code ───
                  _buildQrContainer(qrData),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Actions ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() => _buildActionButton(
                    icon: AppIconAssets.downloadIcon,
                    label: _isSaving.value
                        ? '${AppStrings.saving.tr}...'
                        : 'Download',
                    onTap: _isSaving.value
                        ? null
                        : (widget.onDownload ?? _saveQrToGallery),
                  )),
              const SizedBox(width: 10),
              Obx(() => _buildActionButton(
                    icon: AppIconAssets.reelShare,
                    label: 'Share',
                    onTap: _isSharing.value
                        ? null
                        : (widget.onShare ?? _shareQr),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrContainer(String qrData) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: SizeConfig.screenWidth - (2 * SizeConfig.size80),
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        gapless: true,
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.greyE5, width: 1.0),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          children: [
            LocalAssets(
              imagePath: icon,
              height: 20,
              width: 20,
              boxFix: BoxFit.cover,
              imgColor: AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 10),
            CustomText(
              label,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing business QR: $e');
      return null;
    }
  }

  Future<bool> _ensureGalleryAccess() async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (hasAccess) return true;
    final granted = await Gal.requestAccess(toAlbum: true);
    if (granted) return true;
    _showPermissionSettingsDialog();
    return false;
  }

  void _showPermissionSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogCtx),
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
              Navigator.pop(dialogCtx);
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

  Future<File?> _writeQrToTempFile() async {
    final pngBytes = await _captureQrImage();
    if (pngBytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final id = widget.data?.userId ?? widget.data?.id ?? 'business';
    final file = File(
        '${tempDir.path}/blueera_qr_${id}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  Future<void> _saveQrToGallery() async {
    if (_isSaving.value) return;
    _isSaving.value = true;
    File? tempFile;
    try {
      final hasAccess = await _ensureGalleryAccess();
      if (!hasAccess) return;

      tempFile = await _writeQrToTempFile();
      if (tempFile == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }

      await Gal.putImage(tempFile.path, album: 'BlueEra');
      commonSnackBar(message: AppStrings.qrCodeSavedToGallery.tr);
    } catch (e) {
      debugPrint('Error saving business QR: $e');
      commonSnackBar(message: AppStrings.failedToSaveQrCode.tr);
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      _isSaving.value = false;
    }
  }

  Future<void> _shareQr() async {
    if (_isSharing.value) return;
    _isSharing.value = true;
    try {
      final tempFile = await _writeQrToTempFile();
      if (tempFile == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }
      // Share the QR image only — no deep-link text in the share sheet.
      await SharePlus.instance.share(ShareParams(
        files: [XFile(tempFile.path)],
      ));
    } catch (e) {
      debugPrint('Error sharing business QR: $e');
    } finally {
      _isSharing.value = false;
    }
  }
}
