import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_screen.dart';

class EmergencyQrWidget extends StatelessWidget {
  EmergencyQrWidget({super.key});

  final GlobalKey _qrKey = GlobalKey();
  final RxBool _isSaving = false.obs;

  String get _qrData => 'https://emergency.blueera.ai/$userId';
  final controller = Get.find<EmergencyProfileController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.hasEmergencyData.value) {
        return _buildActiveQr(context);
      } else {
        return _buildDisabledQr(context, controller);
      }
    });
  }

  Widget _buildActiveQr(BuildContext context) {
    return RepaintBoundary(
        key: _qrKey,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                controller.fullName.value.isNotEmpty
                    ? controller.fullName.value
                    : AppStrings.emergencyQr.tr,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200,
                      gapless: true,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1A1A2E),
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1A2E),
                      ),
                      errorStateBuilder: (context, error) => Center(
                        child: CustomText(AppStrings.qrError.tr),
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.black,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const CustomText(
                        'BE',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                        letterSpacing: 1,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.whiteE5,
                    )),
                child: CustomText(
                  AppStrings.scanAndVisit.tr,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrDesignOptionsScreen(
                        userName: controller.fullName.value,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.style_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      CustomText(
                        AppStrings.viewMoreDesigns.tr,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledQr(
      BuildContext context, EmergencyProfileController controller) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.vehicleSafetyParkingQrCode.tr,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.25,
                    child: QrImageView(
                      data: 'https://blueera.ai',
                      version: QrVersions.auto,
                      size: 200,
                      gapless: true,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.grey,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const CustomText(
                      'BE',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomText(
              AppStrings.pasteItToSaveLives.tr,
              color: Color(0xffD7A302),
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                controller.navigateToCreateProfile();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor,
                    )),
                child: CustomText(
                  AppStrings.generateNow.tr,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing QR: $e");
      return null;
    }
  }

  Future<void> _saveQrToGallery() async {
    _isSaving.value = true;
    try {
      final pngBytes = await _captureQrImage();
      if (pngBytes == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          commonSnackBar(message: AppStrings.storagePermissionRequired.tr);
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          commonSnackBar(message: AppStrings.photosPermissionRequired.tr);
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/emergency_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      commonSnackBar(message: AppStrings.qrCodeSavedSuccessfully.tr);
    } catch (e) {
      debugPrint("Error saving QR: $e");
      commonSnackBar(message: AppStrings.failedToSaveQrCode.tr);
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _shareQr() async {
    try {
      final pngBytes = await _captureQrImage();
      if (pngBytes == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/emergency_qr.png').create();
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: "${AppStrings.myEmergencyQrCode.tr}\n$_qrData",
      ));

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error sharing QR: $e");
    }
  }
}
