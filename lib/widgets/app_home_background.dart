import 'dart:io';
import 'dart:ui' as ui;

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
///  - A bundled asset banner → shown as-is, no blur ([Image.asset]).
///  - A user-picked gallery photo → lightly blurred + frosted (glassmorphic)
///    so busy photos read softly behind the app's white cards ([Image.file]).
///  - No banner ('')        → the chosen background colour ([ctrl.bgColor]).
///
/// The blur is applied with [ImageFiltered] — a static, one-off filter on the
/// photo itself. A [BackdropFilter] must NEVER be used here: see the note in
/// [build].
///
/// Asset vs. file is decided by [AppBackgroundController.bannerIsAsset].
class AppHomeBackground extends StatelessWidget {
  const AppHomeBackground({super.key});

  /// Light glassmorphic treatment — gallery photos only.
  static const double _blurSigma = 7;
  static const double _frostAlpha = 0.10;

  @override
  Widget build(BuildContext context) {
    final ctrl = getOrPut(() => AppBackgroundController(), permanent: true);
    return Positioned.fill(
      child: Obx(() {
        final banner = ctrl.bannerAsset.value;
        final color = ctrl.bgColor.value;
        if (banner.isEmpty) return Container(color: color);

        // Bundled asset banner: shown plain, no glassmorphic effect.
        if (AppBackgroundController.bannerIsAsset(banner)) {
          return Image.asset(banner,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: color));
        }

        // User-picked gallery photo: light blur + frost so it sits well under
        // the app's white cards.
        //
        // [ImageFiltered], NOT [BackdropFilter]. The two look identical here
        // but do very different work: ImageFiltered blurs THIS image once, as
        // it paints, while a BackdropFilter forces a full-screen `saveLayer`
        // and re-samples the backdrop every frame — behind EVERY route in the
        // app, since this widget lives in `GetMaterialApp.builder`, and
        // unclipped at that. On some Android GPU/driver combos those samples
        // are not invalidated correctly and stale tiles get re-blitted, which
        // showed up as the whole page smearing and repeating horizontally
        // while scrolling (`assets/discover_bg.jpeg`). Nothing here needs live
        // sampling: the only thing being blurred is a static photo.
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter:
                  ui.ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
              child: Image.file(File(banner),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: color)),
            ),
            // The frost, now a plain overlay — it was only ever the tint laid
            // over the blur, never the thing doing the blurring.
            Container(color: Colors.white.withValues(alpha: _frostAlpha)),
          ],
        );
      }),
    );
  }
}
