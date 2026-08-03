import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A non-interactive map picture, for places where the user only needs to *see*
/// where something is.
///
/// ## Why this exists
///
/// A `GoogleMap` widget bills a **Dynamic Maps load** every time it is created.
/// In a scrolling list that is brutal: list children are disposed when they
/// scroll out of view and rebuilt when they scroll back, so one location message
/// in a chat costs a map load on every pass. (`addAutomaticKeepAlives: true` on
/// the ListView does not save you — it only preserves children that opt in via
/// `AutomaticKeepAliveClientMixin`, which these cards do not.)
///
/// This renders the **Maps Static API** instead:
///
///  * a cheaper SKU per request, and
///  * fetched through [CachedNetworkImage], so it is written to disk once and
///    every later view — same scroll, same session, next launch — is **free**.
///
/// The trade is that the user cannot pan or zoom it. That is the right trade
/// wherever tapping already opens a real full-screen map, which is the case for
/// every current caller.
///
/// ## Requires "Maps Static API" enabled on the key
///
/// It is a separately-enabled API on the Cloud project. If it is not enabled the
/// request 403s and [errorWidget] (or the default placeholder) shows instead of
/// a map — degraded, not broken, but check this before shipping.
/// See `docs/GOOGLE_MAPS_COST_GUIDE.md` §3.5.
class StaticMapPreview extends StatelessWidget {
  const StaticMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.width,
    required this.height,
    this.zoom = 15,
    this.markerColor = 'red',
    this.showMarker = true,
    this.desaturated = false,
    this.borderRadius,
    this.errorWidget,
  });

  final double latitude;
  final double longitude;

  /// Logical size of the image on screen. Used to request the right pixel size,
  /// so we neither buy a 640px image for a thumbnail nor stretch a small one.
  final double width;
  final double height;

  final int zoom;

  /// Static API marker colour name (`red`, `blue`, …) or `0xRRGGBB`.
  final String markerColor;

  /// Draw Google's pin at the centre. Turn this OFF when the caller stacks its
  /// own marker on top — a profile avatar, say — so the two don't collide. The
  /// image is centred on the coordinate either way.
  final bool showMarker;

  /// Greys the image out — used for an expired live-location share, matching
  /// what the interactive card used to do with a [ColorFilter].
  final bool desaturated;

  final BorderRadius? borderRadius;

  /// Shown when the image cannot be loaded — most likely the Static API not
  /// being enabled on the key, or no network.
  final Widget? errorWidget;

  /// The Static API caps a single request at 640x640 logical px (`scale` then
  /// multiplies the actual pixels returned). Anything larger is rejected, so
  /// clamp rather than let the request fail.
  static const int _kMaxSide = 640;

  /// `scale=2` returns double-resolution pixels for the same logical size, which
  /// is what keeps the image sharp on modern screens. Deliberately not tied to
  /// `devicePixelRatio`: 3 costs the same but a 3x-density phone showing a
  /// 254px-wide thumbnail cannot tell the difference, and a per-device URL would
  /// fragment the disk cache.
  static const int _kScale = 2;

  String get _url {
    final w = width.round().clamp(1, _kMaxSide);
    final h = height.round().clamp(1, _kMaxSide);
    final centre = '$latitude,$longitude';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$centre'
        '&zoom=$zoom'
        '&size=${w}x$h'
        '&scale=$_kScale'
        '${showMarker ? '&markers=${Uri.encodeComponent('color:$markerColor|$centre')}' : ''}'
        '&key=$googleMapKey';
  }

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: _url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Flat plate rather than a spinner: the image is usually already on disk,
      // and a spinner that flashes for one frame on every row reads as jank.
      placeholder: (_, __) => Container(color: AppColors.greyE5),
      errorWidget: (_, __, ___) => errorWidget ?? _fallback(),
    );

    if (desaturated) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: image,
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.greyE5,
        alignment: Alignment.center,
        child: const Icon(Icons.location_on,
            color: AppColors.secondaryTextColor, size: 28),
      );
}
