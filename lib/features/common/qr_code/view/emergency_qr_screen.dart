import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class EmergencyQrWidget extends StatelessWidget {
  EmergencyQrWidget({super.key});

  final GlobalKey _qrKey = GlobalKey();
  final RxBool _isSaving = false.obs;

  String get _qrData => 'https://emergency.blueera.ai/$userId';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmergencyProfileController>();

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 0.0),
      child: RepaintBoundary(
        key: _qrKey,
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "Emergency QR",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
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
                        color:  Color(0xFF1A1A2E),
                      ),
                      dataModuleStyle:  QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1A2E),
                      ),
                      errorStateBuilder: (context, error) => const Center(
                        child: CustomText("QR Error"),
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
              const SizedBox(height: 8),
              CustomText(
                "Scan for emergency info",
                fontSize: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() => _actionButton(
                        icon: Icons.download_rounded,
                        label: _isSaving.value ? "Saving..." : "Save",
                        onTap: _isSaving.value ? null : () => _saveQrToGallery(),
                      )),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: Icons.share_rounded,
                    label: "Share",
                    onTap: () => _shareQr(),
                  ),
                ],
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              "Emergency QR",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
                      eyeStyle:  QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.grey,
                      ),
                      dataModuleStyle:  QrDataModuleStyle(
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
              "No emergency data found",
              fontSize: 13,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => controller.navigateToCreateProfile(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create Emergency Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
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
        commonSnackBar(message: "Failed to capture QR code");
        return;
      }

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          commonSnackBar(message: "Storage permission required");
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          commonSnackBar(message: "Photos permission required");
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/emergency_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      commonSnackBar(message: "QR Code saved successfully");
    } catch (e) {
      debugPrint("Error saving QR: $e");
      commonSnackBar(message: "Failed to save QR code");
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _shareQr() async {
    try {
      final pngBytes = await _captureQrImage();
      if (pngBytes == null) {
        commonSnackBar(message: "Failed to capture QR code");
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/emergency_qr.png').create();
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: "My Emergency QR Code\n$_qrData",
      ));

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error sharing QR: $e");
    }
  }
}