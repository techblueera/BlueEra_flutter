import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The single, app-wide background. Painted ONCE as the bottom layer of
/// `GetMaterialApp.builder`, behind every screen. Scaffolds are transparent
/// app-wide (theme `scaffoldBackgroundColor`), so this shows through every
/// screen; content (cards, bubbles, forms) stays opaque on top.
///
/// Returns a [Positioned.fill] so it sits directly inside the builder's
/// [Stack]. Reactive to [AppBackgroundController] — changing the colour or the
/// banner repaints instantly, no theme rebuild needed:
///
///  - A banner is selected → that image (BoxFit.cover).
///  - No banner ('')        → the chosen background colour ([ctrl.bgColor]).
class AppHomeBackground extends StatelessWidget {
  const AppHomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = getOrPut(() => AppBackgroundController(), permanent: true);
    return Positioned.fill(
      child: Obx(() {
        final asset = ctrl.bannerAsset.value;
        final color = ctrl.bgColor.value;
        if (asset.isNotEmpty) {
          return Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: color),
          );
        }
        return Container(color: color);
      }),
    );
  }
}
