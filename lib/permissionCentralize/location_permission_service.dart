import 'dart:developer';
import 'dart:io';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Checks and requests all required permissions.
  /// Returns a tuple: (allGranted, missingPermissionsList)
  static Future<(bool, List<PermissionItem>)> checkAllPermissions() async {
    List<PermissionItem> missingPermissions = [];

    try {
      final locationGranted = await _checkLocationPermissionAndGPS();
      if (!locationGranted) {
        missingPermissions.add(PermissionItem(
          icon: Icons.location_on,
          label: 'Location',
        ));
      }

      // final contactGranted = await _checkContactPermission();
      // if (!contactGranted) {
      //   missingPermissions.add(PermissionItem(
      //     icon: Icons.contacts,
      //     label: 'Contacts',
      //   ));
      // }

      // final galleryGranted = await _checkGalleryPermission();
      // if (!galleryGranted) {
      //   missingPermissions.add(PermissionItem(
      //     icon: Icons.photo_library,
      //     label: 'Gallery',
      //   ));
      // }
      //
      // final cameraGranted = await _checkCameraPermission();
      // if (!cameraGranted) {
      //   missingPermissions.add(PermissionItem(
      //     icon: Icons.camera_alt,
      //     label: 'Camera',
      //   ));
      // }

      // final notificationGranted = await _checkNotificationPermission();
      // if (!notificationGranted) {
      //   missingPermissions.add(PermissionItem(
      //     icon: Icons.notifications,
      //     label: 'Notifications',
      //   ));
      // }

      return (missingPermissions.isEmpty, missingPermissions);
    } catch (e) {
      log('checkAllPermissions error: $e');
      return (false, <PermissionItem>[]);
    }
  }

  // ---------------- LOCATION ----------------
  static Future<bool> _checkLocationPermissionAndGPS() async {
    try {
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied)
            {
              if(Platform.isAndroid){
                await openAppSettings();
              }else{
                commonSnackBar(message: 'Location permission not given , enable it from setting');

                await openAppSettings();

              }
            }
          return false;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return false;
      }

      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      return true;
    } catch (e) {
      log("Location permission error: $e");
      return false;
    }
  }

  // // ---------------- CONTACTS ----------------
  // static Future<bool> _checkContactPermission() async {
  //   try {
  //     var status = await Permission.contacts.status;
  //     if (!status.isGranted) {
  //       status = await Permission.contacts.request();
  //       if (!status.isGranted) {
  //         if (status.isPermanentlyDenied) await openAppSettings();
  //         return false;
  //       }
  //     }
  //     return true;
  //   } catch (e) {
  //     log("Contact permission error: $e");
  //     return false;
  //   }
  // }
  //
  // // ---------------- GALLERY ----------------
  // static Future<bool> _checkGalleryPermission() async {
  //   try {
  //     Permission permission;
  //
  //     if (Platform.isIOS) {
  //       // iOS uses Photos permission (can return limited access)
  //       permission = Permission.photos;
  //     } else {
  //       final deviceInfo = DeviceInfoPlugin();
  //       final androidInfo = await deviceInfo.androidInfo;
  //       final sdkInt = androidInfo.version.sdkInt;
  //
  //       if (sdkInt >= 33) {
  //         // Android 13+ (API 33+): granular media permission
  //         permission = Permission.photos; // You can also use Permission.mediaLibrary
  //       } else {
  //         // Android 12 and below: storage permission
  //         permission = Permission.storage;
  //       }
  //     }
  //
  //     // ✅ Step 1: Check current status
  //     var status = await permission.status;
  //
  //     // ✅ Step 2: Only request if allowed and needed
  //     if (!status.isGranted && !status.isLimited) {
  //       status = await permission.request();
  //     }
  //
  //     // ✅ Step 3: Handle permanently denied
  //     if (status.isPermanentlyDenied) {
  //       await openAppSettings();
  //       return false;
  //     }
  //
  //     // ✅ Step 4: Return true if granted or limited
  //     return status.isGranted || status.isLimited;
  //   } catch (e) {
  //     log("Gallery permission error: $e");
  //     return false;
  //   }
  // }
  //
  //
  // // ---------------- CAMERA ----------------
  // static Future<bool> _checkCameraPermission() async {
  //   try {
  //     var status = await Permission.camera.status;
  //     if (!status.isGranted) {
  //       status = await Permission.camera.request();
  //       if (!status.isGranted) {
  //         if (status.isPermanentlyDenied) await openAppSettings();
  //         return false;
  //       }
  //     }
  //     return true;
  //   } catch (e) {
  //     log("Camera permission error: $e");
  //     return false;
  //   }
  // }

}

/// Model to represent a permission visually
class PermissionItem {
  final IconData icon;
  final String label;

  PermissionItem({required this.icon, required this.label});
}

// import 'dart:developer';
// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class PermissionService {
//   /// Checks and requests all required permissions.
//   /// Returns a tuple: (allGranted, missingPermissionsList)
//   static Future<(bool, List<PermissionItem>)> checkAllPermissions() async {
//     List<PermissionItem> missingPermissions = [];
//
//     try {
//       final locationGranted = await _checkLocationPermissionAndGPS();
//       if (!locationGranted) {
//         missingPermissions.add(PermissionItem(
//           icon: Icons.location_on,
//           label: 'Location',
//         ));
//       }
//
//       // final contactGranted = await _checkContactPermission();
//       // if (!contactGranted) {
//       //   missingPermissions.add(PermissionItem(
//       //     icon: Icons.contacts,
//       //     label: 'Contacts',
//       //   ));
//       // }
//
//       // final galleryGranted = await _checkGalleryPermission();
//       // if (!galleryGranted) {
//       //   missingPermissions.add(PermissionItem(
//       //     icon: Icons.photo_library,
//       //     label: 'Gallery',
//       //   ));
//       // }
//       //
//       // final cameraGranted = await _checkCameraPermission();
//       // if (!cameraGranted) {
//       //   missingPermissions.add(PermissionItem(
//       //     icon: Icons.camera_alt,
//       //     label: 'Camera',
//       //   ));
//       // }
//
//       final notificationGranted = await _checkNotificationPermission();
//       if (!notificationGranted) {
//         missingPermissions.add(PermissionItem(
//           icon: Icons.notifications,
//           label: 'Notifications',
//         ));
//       }
//
//       return (missingPermissions.isEmpty, missingPermissions);
//     } catch (e) {
//       log('checkAllPermissions error: $e');
//       return (false, <PermissionItem>[]);
//     }
//   }
//
//   // ---------------- LOCATION ----------------
//   static Future<bool> _checkLocationPermissionAndGPS() async {
//     try {
//       var status = await Permission.location.status;
//
//       if (!status.isGranted) {
//         final shouldRequest = await _showPermissionDialog(
//           title: 'Location Permission Needed',
//           message:
//           'Location access helps us provide accurate services near you. Please allow location permission to continue.',
//         );
//
//         if (shouldRequest) {
//           status = await Permission.location.request();
//         } else {
//           return false;
//         }
//       }
//
//       if (status.isPermanentlyDenied) {
//         return await _handlePermanentlyDeniedPermission(
//           title: 'Permission Denied',
//           message:
//           'You have permanently denied location access. Would you like to open settings to allow it?',
//         );
//       }
//
//       if (!status.isGranted) return false;
//
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         await Geolocator.openLocationSettings();
//         serviceEnabled = await Geolocator.isLocationServiceEnabled();
//         if (!serviceEnabled) return false;
//       }
//
//       await Geolocator.getCurrentPosition(
//         locationSettings:
//         const LocationSettings(accuracy: LocationAccuracy.high),
//       );
//
//       return true;
//     } catch (e) {
//       log("Location permission error: $e");
//       return false;
//     }
//   }
//
//   // ---------------- CONTACTS ----------------
//   static Future<bool> _checkContactPermission() async {
//     try {
//       var status = await Permission.contacts.status;
//
//       if (!status.isGranted) {
//         final shouldRequest = await _showPermissionDialog(
//           title: 'Contacts Permission Required',
//           message:
//           'We need access to your contacts to help you easily connect and share information.',
//         );
//
//         if (shouldRequest) {
//           status = await Permission.contacts.request();
//         } else {
//           return false;
//         }
//       }
//
//       if (status.isPermanentlyDenied) {
//         return await _handlePermanentlyDeniedPermission(
//           title: 'Permission Denied',
//           message:
//           'You have permanently denied contacts access. Would you like to open settings to allow it?',
//         );
//       }
//
//       return status.isGranted;
//     } catch (e) {
//       log("Contact permission error: $e");
//       return false;
//     }
//   }
//
//   // ---------------- GALLERY ----------------
//   static Future<bool> _checkGalleryPermission() async {
//     try {
//       Permission permission;
//
//       if (Platform.isIOS) {
//         permission = Permission.photos;
//       } else {
//         final deviceInfo = DeviceInfoPlugin();
//         final androidInfo = await deviceInfo.androidInfo;
//         final sdkInt = androidInfo.version.sdkInt;
//         permission = sdkInt >= 33 ? Permission.photos : Permission.storage;
//       }
//
//       var status = await permission.status;
//
//       if (!status.isGranted && !status.isLimited) {
//         final shouldRequest = await _showPermissionDialog(
//           title: 'Gallery Access Needed',
//           message:
//           'Please allow gallery access so you can select and upload images from your device.',
//         );
//
//         if (shouldRequest) {
//           status = await permission.request();
//         } else {
//           return false;
//         }
//       }
//
//       if (status.isPermanentlyDenied) {
//         return await _handlePermanentlyDeniedPermission(
//           title: 'Permission Denied',
//           message:
//           'You have permanently denied gallery access. Would you like to open settings to allow it?',
//         );
//       }
//
//       return status.isGranted || status.isLimited;
//     } catch (e) {
//       log("Gallery permission error: $e");
//       return false;
//     }
//   }
//
//   // ---------------- CAMERA ----------------
//   static Future<bool> _checkCameraPermission() async {
//     try {
//       var status = await Permission.camera.status;
//
//       if (!status.isGranted) {
//         final shouldRequest = await _showPermissionDialog(
//           title: 'Camera Permission Required',
//           message:
//           'We need camera access so you can take photos or videos directly from the app.',
//         );
//
//         if (shouldRequest) {
//           status = await Permission.camera.request();
//         } else {
//           return false;
//         }
//       }
//
//       if (status.isPermanentlyDenied) {
//         return await _handlePermanentlyDeniedPermission(
//           title: 'Permission Denied',
//           message:
//           'You have permanently denied camera access. Would you like to open settings to allow it?',
//         );
//       }
//
//       return status.isGranted;
//     } catch (e) {
//       log("Camera permission error: $e");
//       return false;
//     }
//   }
//
//
//   // ---------------- NOTIFICATION ----------------
//   static Future<bool> _checkNotificationPermission() async {
//     try {
//       NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//
//       if (settings.authorizationStatus == AuthorizationStatus.authorized ||
//           settings.authorizationStatus == AuthorizationStatus.provisional) {
//         return true;
//       }
//
//       // ❌ Not granted — show dialog
//       final shouldRequest = await _showPermissionDialog(
//         title: 'Notification Permission Required',
//         message:
//         'We use notifications to keep you updated with important alerts. Please allow notification access.',
//       );
//
//       if (shouldRequest) {
//         final newSettings = await FirebaseMessaging.instance.requestPermission(
//           alert: true,
//           badge: true,
//           sound: true,
//         );
//
//         if (newSettings.authorizationStatus == AuthorizationStatus.denied) {
//           return await _handlePermanentlyDeniedPermission(
//             title: 'Permission Denied',
//             message:
//             'You have permanently denied notification access. Would you like to open settings to allow it?',
//           );
//         }
//
//         return newSettings.authorizationStatus == AuthorizationStatus.authorized ||
//             newSettings.authorizationStatus == AuthorizationStatus.provisional;
//       }
//
//       return false;
//     } catch (e) {
//       log("Notification permission error: $e");
//       return false;
//     }
//   }
//
//   static Future<bool> _handlePermanentlyDeniedPermission({
//     required String title,
//     required String message,
//   }) async {
//     if (Platform.isAndroid) {
//       await openAppSettings();
//       return false;
//     } else {
//       await _showPermissionDialog(
//         title: title,
//         message: message,
//       );
//       // final openSettings = await _showPermissionDialog(
//       //   title: title,
//       //   message: message,
//       // );
//       // if (openSettings) await openAppSettings();
//       return false;
//     }
//   }
//
//   static Future<bool> _showPermissionDialog({
//     required String title,
//     required String message,
//   }) async {
//     bool granted = false;
//
//     await Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back(); // close dialog
//             },
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               granted = true;
//               Get.back(); // close dialog
//             },
//             child: const Text('Allow'),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );
//
//     return granted;
//   }
//
// }
//
// /// Model to represent a permission visually
// class PermissionItem {
//   final IconData icon;
//   final String label;
//
//   PermissionItem({required this.icon, required this.label});
// }
