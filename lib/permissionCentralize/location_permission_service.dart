import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks and requests location permission.
  static Future<bool> checkLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Request the permission
      status = await Permission.location.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permanently denied
      await openAppSettings();
      return false;
    }

    return false;
  }
}
