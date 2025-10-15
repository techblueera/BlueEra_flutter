
import 'package:BlueEra/features/common/onboarding/view/splash_screen.dart';
import 'package:BlueEra/permissionCentralize/location_permission_service.dart';
import 'package:BlueEra/permissionCentralize/permission_request_screen.dart';
import 'package:flutter/material.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool? hasPermission;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool granted = await PermissionService.checkLocationPermissionAndGPS();
    setState(() {
      hasPermission = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasPermission == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return hasPermission!
        ? const SplashScreen()
        : const PermissionRequiredScreen();
  }
}