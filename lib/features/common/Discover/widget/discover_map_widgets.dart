import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Banner-style circular icon button (black 35% backdrop, white icon).
/// Reused across the inline map preview and full-screen map screens so
/// the back-arrow / recenter affordance looks identical to the original
/// `BannerCarousel`.
Widget bannerMapCircleIconButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size8),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: SizeConfig.size20),
      ),
    ),
  );
}

/// Banner-style location pill (black 35% backdrop, white icon + locality
/// label + chevron). Mirrors the pill from `BannerCarousel`.
///
/// Pass [label] to pin a specific location (e.g. a place the user searched for
/// in the Book-Home-Services flow); omit it to reactively show the device's
/// current locality from [LocationService].
Widget bannerMapLocationPill({String? label}) {
  if (label != null && label.trim().isNotEmpty) {
    return _locationPillShell(label);
  }
  return Obx(() {
    final loc = LocationService.userCurrentAddress.value;
    final title =
        [loc.subLocality, loc.city].where((e) => e.isNotEmpty).join(', ');
    return _locationPillShell(
        title.isEmpty ? AppStrings.selectLocationPill.tr : title);
  });
}

Widget _locationPillShell(String title) {
  return Container(
    padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10, vertical: SizeConfig.size8),
    decoration: BoxDecoration(
      color: AppColors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined,
            color: AppColors.white, size: SizeConfig.size20),
        SizedBox(width: SizeConfig.size6),
        Flexible(
          child: CustomText(
            title,
            fontSize: SizeConfig.medium,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: SizeConfig.size4),
        Icon(Icons.keyboard_arrow_down,
            color: AppColors.white, size: SizeConfig.size18),
      ],
    ),
  );
}

/// Inline tap-to-expand map preview that replaces the static
/// `BannerCarousel` on Discover screens. Non-interactive (gestures
/// absorbed) — tapping anywhere on it calls [onTap], which is expected
/// to push the dedicated full-screen cluster map. Bottom corners are
/// rounded to match the banner so the screen rhythm stays consistent.
class DiscoverMapPreview extends StatelessWidget {
  final double statusBarHeight;
  final VoidCallback onTap;
  final double initialZoom;
  final double height;

  /// Optional camera center. When set (e.g. a place picked in the Book-Home-
  /// Services flow), the preview frames that location instead of the device
  /// fix. Its label should be passed via [locationLabel] so the pill agrees.
  final LatLng? center;

  /// Optional pinned label for the location pill (the picked place). Null →
  /// the pill reactively shows the device's current locality.
  final String? locationLabel;

  const DiscoverMapPreview({
    super.key,
    required this.statusBarHeight,
    required this.onTap,
    this.initialZoom = 12,
    this.height = 230,
    this.center,
    this.locationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final target = center ??
        LatLng(
          LocationService.lat != 0.0 ? LocationService.lat : 28.6139,
          LocationService.lng != 0.0 ? LocationService.lng : 77.2090,
        );

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Stack(
        children: [
          Container(
            height: height + statusBarHeight,
            decoration: BoxDecoration(
              color: AppColors.blue5CAF.withValues(alpha: 0.1),
              border: const Border(
                bottom: BorderSide(color: AppColors.white, width: 2),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: statusBarHeight),
              child: AbsorbPointer(
                absorbing: true,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: target,
                    zoom: initialZoom,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
          // Tap target overlay that catches taps anywhere on the preview.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            top: statusBarHeight + SizeConfig.size4,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                bannerMapCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(child: bannerMapLocationPill(label: locationLabel)),
              ],
            ),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      CustomText(
                        AppStrings.viewOnMap.tr,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generates `BitmapDescriptor` marker icons that look more polished
/// than the default red Google pin: a colored circle with a white inner
/// disc and a category icon at the centre. Results are cached by
/// `(icon, color, size)` so subsequent calls are free.
class DiscoverMarkerIcons {
  static final Map<int, BitmapDescriptor> _cache = {};

  /// A circular marker with a soft halo, white ring and a glyph drawn
  /// from [icon] in the centre. [color] tints the ring and the icon —
  /// pass [AppColors.primaryColor] for the brand pin or any accent for
  /// category-specific maps.
  static Future<BitmapDescriptor> circle({
    required IconData icon,
    Color? color,
    int size = 110,
  }) async {
    final fillColor = color ?? AppColors.primaryColor;
    final cacheKey = Object.hash(
      icon.codePoint,
      icon.fontFamily,
      // ignore: deprecated_member_use
      fillColor.value,
      size,
    );
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final cx = size / 2.0;
    final cy = size / 2.0;

    // Soft halo
    final haloPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(cx, cy), size / 2.0, haloPaint);

    // White ring (acts as the border for the inner disc)
    final ringPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), size / 2.0 - 8, ringPaint);

    // Inner colored disc
    final fillPaint = Paint()..color = fillColor;
    canvas.drawCircle(Offset(cx, cy), size / 2.0 - 14, fillPaint);

    // Glyph
    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size / 2.6,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(cx - painter.width / 2, cy - painter.height / 2),
    );

    final img =
        await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    _cache[cacheKey] = descriptor;
    return descriptor;
  }
}
