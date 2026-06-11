import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Drives the single, app-wide background.
///
/// Scaffolds are transparent app-wide (theme `scaffoldBackgroundColor`), and
/// `AppHomeBackground` in `GetMaterialApp.builder` paints ONE background behind
/// every screen, reactively from this controller's observables. No theme
/// rebuild is needed — mutating [bgColor] / [bannerAsset] repaints instantly.
///
/// MUTUALLY EXCLUSIVE — only ONE background is ever active:
///
///  - [bgColor]    → the app background colour.
///  - [bannerAsset]→ the app background banner image.
///
/// Invariant: a non-empty [bannerAsset] means the banner IS the background and
/// [bgColor] is forced back to default (so it never competes); an empty
/// [bannerAsset] means [bgColor] is the background. Picking one clears the
/// other — see [applyBackground]. [AppColors.appBackgroundColor] mirrors
/// [bgColor] for the handful of widgets that still read the colour directly.
///
/// Persistence: every change is saved to the [_boxName] Hive box and reapplied
/// on next launch ([preload] before first frame, [_load] for the reactive
/// state). On logout / data-clear the box is wiped by
/// `LogoutHelper.clearAllLocalData()`, which also calls [resetInMemory] so the
/// live state falls back to defaults without a restart.
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
    // Darker "lighter-dark" tones — white cards pop nicely on these.
    [Color(0xFF37474F), 'Slate'],
    [Color(0xFF2C3E50), 'Navy'],
    [Color(0xFF4E4A59), 'Charcoal'],
    [Color(0xFF3E4A3D), 'Forest'],
    [Color(0xFF5D4954), 'Plum'],
    [Color(0xFF4A3B33), 'Mocha'],
  ];

  /// Banner images offered on the picker. `{asset, name}`.
  static const List<Map<String, String>> bannerOptions = [
    {'asset': AppImageAssets.chatDefaultBg, 'name': 'Default'},
    {'asset': AppImageAssets.chatBgLight, 'name': 'Light'},
    {'asset': AppImageAssets.chatBgBlueShade, 'name': 'Blue'},
    // {'asset': AppImageAssets.shopBanner, 'name': 'Shop'},
  ];

  /// A bundled asset banner (vs a user-picked gallery file). Asset paths begin
  /// with `assets/`; gallery files are absolute paths. Drives whether
  /// `AppHomeBackground` uses `Image.asset` or `Image.file`.
  static bool bannerIsAsset(String banner) => banner.startsWith('assets');

  /// Copy a picked gallery image into app storage so it survives restarts
  /// (picker temp files get cleared) and a fresh path defeats the image cache.
  /// Removes any previous custom background first, then returns the stable path.
  static Future<String> persistPickedBanner(String srcPath) async {
    final dir = await getApplicationDocumentsDirectory();
    for (final f in dir.listSync()) {
      if (f is File && f.uri.pathSegments.last.startsWith('app_bg_custom_')) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    final ext = srcPath.contains('.') ? srcPath.split('.').last : 'jpg';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dest = '${dir.path}/app_bg_custom_$stamp.$ext';
    await File(srcPath).copy(dest);
    return dest;
  }

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

  /// Mirror the persisted colour into [AppColors.appBackgroundColor] BEFORE the
  /// first frame, for the few widgets that read the colour directly. Call from
  /// `main()` after `Hive.initFlutter()`.
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

  /// Commit the single active background. EXACTLY ONE wins:
  ///
  ///  - [asset] non-empty → that banner becomes the background and [bgColor] is
  ///    forced back to default, so the colour never competes with it.
  ///  - [asset] empty      → [color] becomes the background.
  ///
  /// `AppHomeBackground` repaints reactively from [bgColor] / [bannerAsset]; no
  /// theme rebuild is needed. The choice is persisted.
  void applyBackground({required Color color, required String asset}) {
    bannerAsset.value = asset;
    bgColor.value =
        asset.isEmpty ? color : AppColors.appBackgroundColorDefault;
    AppColors.appBackgroundColor = bgColor.value;
    _save();
  }

  /// Reset BOTH settings to defaults: default colour + no banner.
  void resetAll() {
    bgColor.value = AppColors.appBackgroundColorDefault;
    bannerAsset.value = '';
    AppColors.appBackgroundColor = AppColors.appBackgroundColorDefault;
    _save();
  }

  /// Reset the LIVE (in-memory) background to defaults — for logout / data
  /// clear, where the Hive box is wiped on disk but the live state would
  /// otherwise linger until the next restart. Safe with no registered instance.
  static void resetInMemory() {
    AppColors.appBackgroundColor = AppColors.appBackgroundColorDefault;
    if (Get.isRegistered<AppBackgroundController>()) {
      final c = Get.find<AppBackgroundController>();
      c.bgColor.value = AppColors.appBackgroundColorDefault;
      c.bannerAsset.value = '';
    }
  }
}
