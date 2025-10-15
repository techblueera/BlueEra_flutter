import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/permissionCentralize/location_permission_service.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class PermissionRequiredScreen extends StatelessWidget {
  const PermissionRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 100, color: Colors.red),
             SizedBox(height: SizeConfig.size20),
             CustomText(
              "Location Permission Required",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
            ),
             Padding(
              padding: EdgeInsets.all(SizeConfig.size16),
              child: CustomText(
                "This app requires location access to function. Please enable it in settings.",
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size50),
              child: PositiveCustomBtn(
                  onTap: () async {
                    bool granted =
                        await PermissionService.checkLocationPermissionAndGPS();
                    if (granted && context.mounted) {
                      Navigator.pushReplacementNamed(context,  RouteHelper.getSplashScreenRoute());
                    }
                  },
                  title: "Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }
}
