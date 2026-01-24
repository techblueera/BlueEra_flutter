import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> checkAppVersionAndResetIfNeeded() async {
  final box = await Hive.openBox('app_info');
  await Hive.openBox('translations');

  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  final savedVersion = box.get('app_version');

  if (savedVersion != currentVersion) {
    print("🚀 App updated from $savedVersion → $currentVersion");

    // ✅ Reset language localization (only once after update)
    await resetLanguageLocalization();

    // Save the current version
    await box.put('app_version', currentVersion);
  } else {
    print("✅ App version unchanged ($currentVersion)");
  }
}
