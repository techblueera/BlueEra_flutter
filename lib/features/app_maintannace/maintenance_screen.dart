// lib/view/maintenance_screen.dart
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/app_maintannace/app_maintenance_controller.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appMaintenanceController = Get.find<AppMaintenanceController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              return appMaintenanceController.isLoading.value
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build_circle_outlined,
                            size: 100, color: AppColors.primaryColor),
                        const SizedBox(height: 24),
                        CustomText(
                          'Under Maintenance',
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size22,
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          "${appMaintenanceController.message.value}",
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.size18,
                        ),
                        const SizedBox(height: 32),

                        PositiveCustomBtn(
                            bgColor: AppColors.primaryColor,
                            borderColor: AppColors.primaryColor,
                            onTap: appMaintenanceController.checkMaintenance,
                            title: "Retry")
                      ],
                    );
            }),
          ),
        ),
      ),
    );
  }
}
