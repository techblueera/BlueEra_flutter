
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/personal/emergency/controller/emergency_profile_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:BlueEra/features/common/qr_code/view/qr_design_options_screen.dart';

class EmergencyQrWidget extends StatelessWidget {
  EmergencyQrWidget({super.key});

  final GlobalKey _qrKey = GlobalKey();

  String get _qrData => 'https://emergency.beapp.in/$userId';
  // Use getOrPut (not Get.find) so this widget is self-sufficient: it registers
  // and lazily loads the controller if the host screen hasn't already. Guards
  // against "controller not found" when the widget is built before/without the
  // Discover screen's initState registration (e.g. after a hot reload or if the
  // controller was disposed).
  final controller = getOrPut(() => EmergencyProfileController());

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
                      data: 'https://beapp.in',
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



}
