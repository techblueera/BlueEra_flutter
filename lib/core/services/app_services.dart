import 'package:permission_handler/permission_handler.dart';

class AppServices {

  // AGORA
  static const String agoraAppId = '381854d62adf4168afb825420f52539d'; // development
  // static const String agoraAppId = ''; // production (// todo : add)
  //App signature

  //One Signal app id
  static const String oneSignalAppId = '0f8a3218-2a6a-4811-b352-cb1c8c2b58d7';

  static Future<void> permissionHandler() async {
    await _requestIfNotGranted(Permission.notification);
    await _requestIfNotGranted(Permission.audio);
    await _requestIfNotGranted(Permission.camera);
    await _requestIfNotGranted(Permission.microphone);
    await _requestIfNotGranted(Permission.systemAlertWindow);
  }

  static Future<void> _requestIfNotGranted(Permission permission) async {
    final status = await permission.status;
    if (!status.isGranted) {
      await permission.request();
    }
  }

}
