import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Background customisation for the profile / home ("me" tab) pages.
///
/// Two INDEPENDENT settings — changing one never clears the other:
///
///  - [bgColor]    → the app background colour. Recolours
///                   [AppColors.appBackgroundColor] + the theme's
///                   `scaffoldBackgroundColor` app-wide.
///  - [bannerAsset]→ the home-page banner image painted by each resolved
///                   screen's `_buildPatternBackground()` (via the shared
///                   `AppHomeBackground` widget). Empty string = no banner, so
///                   the home page shows [bgColor] instead.
///
/// Persistence: every change is saved to the [_boxName] Hive box and reapplied
/// on next launch ([preload] for colour before first frame, [_load] for the
/// reactive state). On logout / data-clear the box is wiped by
/// `LogoutHelper.clearAllLocalData()`, which also calls [resetInMemory] so the
/// live statics fall back to defaults without a restart.
class AppBackgroundController extends GetxController {
  /// The app background colour. Defaults to [AppColors.appBackgroundColorDefault].
  final Rx<Color> bgColor = const Color(0xFFE0E6F3).obs;

  /// Home-page banner image asset, or '' for none (→ show [bgColor]).
  final RxString bannerAsset = ''.obs;

  static const String _boxName = 'app_background_settings';

  /// Colour swatches offered on the picker. `[Color, label]`. The first entry
  /// is the app's default background — picking it (or Reset) restores the
  /// original look.
  static const List<List<Object>> colorOptions = [
    [AppColors.appBackgroundColorDefault, 'Default'],
    [Color(0xFFF5F0E8), 'Cream'],
    [Color(0xFFE8F5E9), 'Mint'],
    [Color(0xFFE3F2FD), 'Sky'],
    [Color(0xFFFCE4EC), 'Rose'],
    [Color(0xFFFFF8E1), 'Honey'],
    [Color(0xFFF3E5F5), 'Lilac'],
    [Color(0xFFE0F2F1), 'Teal'],
    [Color(0xFFFBE9E7), 'Peach'],
    [Color(0xFFE0F7FA), 'Aqua'],
    [Color(0xFFEDE7F6), 'Lavender'],
    [Color(0xFFF1F8E9), 'Sage'],
    [Color(0xFFFFF3E0), 'Sand'],
    [Color(0xFFE8EAF6), 'Periwinkle'],
    [Color(0xFFECEFF1), 'Cloud'],
    [Color(0xFFFFEBEE), 'Blush'],
  ];

  /// Banner images offered on the picker. `{asset, name}`.
  static const List<Map<String, String>> bannerOptions = [
    {'asset': AppImageAssets.chatDefaultBg, 'name': 'Default'},
    {'asset': AppImageAssets.chatBgLight, 'name': 'Light'},
    {'asset': AppImageAssets.chatBgBlueShade, 'name': 'Blue'},
    {'asset': AppImageAssets.shopBanner, 'name': 'Shop'},
  ];

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>(_boxName);
    final colorValue = int.tryParse(box.get('bgColor', defaultValue: '') ?? '');
    if (colorValue != null) {
      bgColor.value = Color(colorValue);
      AppColors.appBackgroundColor = bgColor.value;
    }
    bannerAsset.value = box.get('bannerAsset', defaultValue: '') ?? '';
  }

  /// Reapply the persisted colour to [AppColors.appBackgroundColor] BEFORE the
  /// first frame so a saved colour is themed from launch. Call from `main()`
  /// after `Hive.initFlutter()`.
  static Future<void> preload() async {
    final box = await Hive.openBox<String>(_boxName);
    final colorValue = int.tryParse(box.get('bgColor', defaultValue: '') ?? '');
    if (colorValue != null) AppColors.appBackgroundColor = Color(colorValue);
  }

  Future<void> _save() async {
    final box = await Hive.openBox<String>(_boxName);
    // ignore: deprecated_member_use
    await box.put('bgColor', bgColor.value.value.toString());
    await box.put('bannerAsset', bannerAsset.value);
  }

  /// Apply a solid colour. Recolours [AppColors.appBackgroundColor] and the
  /// theme's `scaffoldBackgroundColor` app-wide (so every screen reading them
  /// updates), then persists. Independent of [bannerAsset].
  void applyColor(Color color) {
    bgColor.value = color;
    AppColors.appBackgroundColor = color;
    Get.changeTheme(AppThemes.light);
    _save();
  }

  /// Apply a home-page banner (or '' for none) and persist. Independent of
  /// [bgColor] — selecting a banner never changes the colour.
  void applyBanner(String asset) {
    bannerAsset.value = asset;
    _save();
  }

  /// Reset BOTH settings to defaults: default colour app-wide + no banner.
  void resetAll() {
    bgColor.value = AppColors.appBackgroundColorDefault;
    bannerAsset.value = '';
    AppColors.appBackgroundColor = AppColors.appBackgroundColorDefault;
    Get.changeTheme(AppThemes.light);
    _save();
  }

  /// Reset the LIVE (in-memory) background to defaults — for logout / data
  /// clear, where the Hive box is wiped on disk but the static colour would
  /// otherwise linger until the next restart. Safe with no registered
  /// instance.
  static void resetInMemory() {
    AppColors.appBackgroundColor = AppColors.appBackgroundColorDefault;
    if (Get.isRegistered<AppBackgroundController>()) {
      final c = Get.find<AppBackgroundController>();
      c.bgColor.value = AppColors.appBackgroundColorDefault;
      c.bannerAsset.value = '';
    }
    Get.changeTheme(AppThemes.light);
  }
}
