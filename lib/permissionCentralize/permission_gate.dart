import 'package:BlueEra/permissionCentralize/location_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/common/onboarding/view/splash_screen.dart';
import 'package:BlueEra/permissionCentralize/permission_required_screen.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool? hasPermission;
  List<PermissionItem> missingPermissions = [];

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final (granted, missing) = await PermissionService.checkAllPermissions();
    setState(() {
      hasPermission = granted;
      missingPermissions = missing;
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
        : PermissionRequiredScreen(
      missingPermissions: missingPermissions,
      onRetry: _checkAllPermissions,
    );
  }
}
