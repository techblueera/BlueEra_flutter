import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/permissionCentralize/location_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class PermissionRequiredScreen extends StatelessWidget {
  final List<PermissionItem> missingPermissions;
  final Future<void> Function() onRetry;

  const PermissionRequiredScreen({
    super.key,
    required this.missingPermissions,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 100, color: Colors.redAccent),
              SizedBox(height: SizeConfig.size20),

              CustomText(
                "Permissions Required",
                fontSize: SizeConfig.large18,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
              ),

              SizedBox(height: SizeConfig.size20),

              // 🔹 Dynamic list of only missing permissions
              ...missingPermissions.map((item) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size10),
                      Flexible(
                        child: CustomText(
                          item.label,
                          fontSize: SizeConfig.medium,
                          textAlign: TextAlign.center,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              SizedBox(height: SizeConfig.size30),

              CustomText(
                "Please grant these permissions to continue.",
                textAlign: TextAlign.center,
                fontSize: SizeConfig.size14,
                color: Colors.black54,
              ),

              SizedBox(height: SizeConfig.size30),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size50),
                child: PositiveCustomBtn(
                  onTap: () async {
                    await onRetry();
                  },
                  title: "Grant Permissions",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
