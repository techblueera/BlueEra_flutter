import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Personal-profile twin of `BusinessQrCodeWidget`.
///
/// Renders a card with the user's profile-deep-link QR centered, with
/// [name] and (optionally) [designation] above it — designation styled
/// with the same pill the business card uses for sub-category — plus
/// Download and Share actions identical to the business card.
class PersonalQrCodeWidget extends StatefulWidget {
  /// Used to build the deep-link payload and to seed temp-file names.
  /// Renders nothing when empty so callers can safely pass an
  /// uninitialised id while the profile is still loading.
  final String userId;

  /// Display name shown above the QR.
  final String name;

  /// Optional designation/title; shows as a pill below the name when set.
  final String? designation;

  /// Outer margin override. Defaults to the same top spacing
  /// `BusinessQrCodeWidget` uses so the card spaces itself the same
  /// way out-of-the-box.
  final EdgeInsetsGeometry margin;

  /// Optional override; when null, the widget captures the QR card and
  /// saves it to the gallery via Gal under a "BlueEra" album.
  final VoidCallback? onDownload;

  /// Optional override; when null, the widget shares the captured QR
  /// image only (no deep-link text).
  final VoidCallback? onShare;

  /// Optional deep-link override encoded into the QR. When null, the
  /// widget falls back to the generic [profileDeepLink]. Callers that
  /// want the scan to open a specific screen (e.g. the professionals /
  /// consultant detail via [professionalsConsultantDeepLink]) pass the
  /// fully-built link here.
  final String? deepLinkOverride;

  const PersonalQrCodeWidget({
    super.key,
    required this.userId,
    required this.name,
    this.designation,
    this.margin = const EdgeInsets.only(top: 10.0),
    this.onDownload,
    this.onShare,
    this.deepLinkOverride,
  });

  @override
  State<PersonalQrCodeWidget> createState() => _PersonalQrCodeWidgetState();
}

class _PersonalQrCodeWidgetState extends State<PersonalQrCodeWidget> {
  final GlobalKey _repaintKey = GlobalKey();
  final RxBool _isSaving = false.obs;
  final RxBool _isSharing = false.obs;

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();
    final override = widget.deepLinkOverride?.trim() ?? '';
    final qrData = override.isNotEmpty ? override : profileDeepLink(userId: widget.userId);

    return CustomFormCard(
      padding: const EdgeInsets.all(10.0),
      margin: widget.margin,
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
                  // ─── Name ───
                  CustomText(
                    widget.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),

                  const SizedBox(height: 10),

                  // ─── Designation pill ───
                  // Reusing the business sub-category pill keeps the
                  // visual treatment identical across both cards.
                  BusinessCommonSubCategoryWidget(
                    label: widget.designation,
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
                        : AppStrings.download.tr,
                    onTap: _isSaving.value
                        ? null
                        : (widget.onDownload ?? _saveQrToGallery),
                  )),
              const SizedBox(width: 10),
              Obx(() => _buildActionButton(
                    icon: AppIconAssets.reelShare,
                    label: AppStrings.share.tr,
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
      debugPrint('Error capturing personal QR: $e');
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
    final id = widget.userId.isNotEmpty ? widget.userId : 'personal';
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
      debugPrint('Error saving personal QR: $e');
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
      debugPrint('Error sharing personal QR: $e');
    } finally {
      _isSharing.value = false;
    }
  }
}
