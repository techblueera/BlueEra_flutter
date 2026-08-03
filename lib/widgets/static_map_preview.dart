import 'dart:math' as math;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/map/osm_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A non-interactive map picture, for places where the user only needs to *see*
/// where something is.
///
/// ## Why this exists
///
/// An interactive map widget is expensive to create. In a scrolling list that is
/// brutal: list children are disposed when they scroll out of view and rebuilt
/// when they scroll back, so one location message in a chat spins up a fresh map
/// engine on every pass. (`addAutomaticKeepAlives: true` on the ListView does
/// not save you — it only preserves children that opt in via
/// `AutomaticKeepAliveClientMixin`, which these cards do not.)
///
/// This renders **raster map tiles** instead, fetched through
/// [CachedNetworkImage] so they are written to disk once and every later view —
/// same scroll, same session, next launch — is free.
///
/// The trade is that the user cannot pan or zoom it. That is the right trade
/// wherever tapping already opens a real full-screen map, which is the case for
/// every current caller.
///
/// ## Why tiles beat the static-image API this replaced
///
/// The previous implementation called Google's Maps Static API, which returns
/// **one bespoke image per coordinate**. Two shops on the same street produced
/// two entirely separate downloads and two separate cache entries, sharing
/// nothing.
///
/// Tiles are addressed by a fixed `{z}/{x}/{y}` grid, so those two shops resolve
/// to the *same tiles* and the second card costs nothing at all. In a
/// city-dense list — which is the normal case here — the cache hit rate goes up
/// sharply rather than scaling with the number of distinct pins.
///
/// The cost is a little arithmetic: a viewport usually straddles two to four
/// tiles, so this lays out a small grid and clips it, rather than displaying one
/// image. That work is [_TileGrid].
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
    this.showAttribution = true,
  });

  final double latitude;
  final double longitude;

  /// Logical size of the image on screen.
  final double width;
  final double height;

  final int zoom;

  /// Retained from the Static API signature so callers did not have to change.
  /// Accepts the old colour *names* (`red`, `blue`, …) and `0xRRGGBB` strings;
  /// anything unrecognised falls back to the brand colour.
  final String markerColor;

  /// Draw the pin at the centre. Turn this OFF when the caller stacks its own
  /// marker on top — a profile avatar, say — so the two don't collide. The
  /// image is centred on the coordinate either way.
  final bool showMarker;

  /// Greys the image out — used for an expired live-location share.
  final bool desaturated;

  final BorderRadius? borderRadius;

  /// Shown when tiles cannot be loaded — most likely no network.
  final Widget? errorWidget;

  /// OSM data is ODbL-licensed and attribution is a **licence condition, not a
  /// courtesy**. Only pass false where the surrounding UI already credits
  /// OpenStreetMap visibly; do not switch it off merely because the label is
  /// inconvenient at small sizes.
  final bool showAttribution;

  @override
  Widget build(BuildContext context) {
    Widget map = SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _TileGrid(
            latitude: latitude,
            longitude: longitude,
            width: width,
            height: height,
            zoom: zoom,
            errorWidget: errorWidget ?? _fallback(),
          ),
          if (showMarker)
            Center(
              child: _Pin(
                color: _resolveMarkerColor(markerColor),
                // The pin's point sits at its bottom edge, so it must be lifted
                // by half its height for that point — not its centre — to land
                // on the coordinate.
                size: math.min(28.0, height * 0.32),
              ),
            ),
          if (showAttribution) const _Attribution(),
        ],
      ),
    );

    if (desaturated) {
      map = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: map,
      );
    }

    if (borderRadius != null) {
      map = ClipRRect(borderRadius: borderRadius!, child: map);
    }
    return map;
  }

  static Color _resolveMarkerColor(String value) {
    switch (value.toLowerCase()) {
      case 'red':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'green':
        return const Color(0xFF43A047);
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'purple':
        return const Color(0xFF8E24AA);
      case 'black':
        return Colors.black;
      default:
        final hex = value.replaceFirst('0x', '').replaceFirst('#', '');
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null && hex.length == 6) {
          return Color(0xFF000000 | parsed);
        }
        return AppColors.primaryColor;
    }
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

/// Lays out the raster tiles covering the requested viewport.
///
/// Web Mercator, the projection every slippy map uses: the world is one square
/// at zoom 0 and splits into four at each level, so at zoom `z` there are `2^z`
/// tiles per side and each is [_kTileSize] pixels.
class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.latitude,
    required this.longitude,
    required this.width,
    required this.height,
    required this.zoom,
    required this.errorWidget,
  });

  final double latitude;
  final double longitude;
  final double width;
  final double height;
  final int zoom;
  final Widget errorWidget;

  static const double _kTileSize = 256.0;

  /// OSM zoom levels stop at 19; asking for more returns 404s, not a closer
  /// view.
  static const int _kMaxZoom = 19;

  @override
  Widget build(BuildContext context) {
    final z = zoom.clamp(0, _kMaxZoom);
    final scale = math.pow(2, z).toDouble();

    // World pixel coordinates of the centre.
    final centreX = (longitude + 180.0) / 360.0 * scale * _kTileSize;
    final latRad = latitude * math.pi / 180.0;
    final centreY = (1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        scale *
        _kTileSize;

    // Top-left corner of the viewport, in world pixels.
    final originX = centreX - width / 2.0;
    final originY = centreY - height / 2.0;

    final firstTileX = (originX / _kTileSize).floor();
    final lastTileX = ((originX + width) / _kTileSize).floor();
    final firstTileY = (originY / _kTileSize).floor();
    final lastTileY = ((originY + height) / _kTileSize).floor();

    final maxTileIndex = scale.toInt() - 1;
    final tiles = <Widget>[];

    for (var tx = firstTileX; tx <= lastTileX; tx++) {
      for (var ty = firstTileY; ty <= lastTileY; ty++) {
        // Y does not wrap — above the north pole or below the south there is
        // simply no tile. X does wrap, so the antimeridian is handled rather
        // than left blank.
        if (ty < 0 || ty > maxTileIndex) continue;
        final wrappedX = ((tx % scale.toInt()) + scale.toInt()) % scale.toInt();

        tiles.add(
          Positioned(
            left: tx * _kTileSize - originX,
            top: ty * _kTileSize - originY,
            width: _kTileSize,
            height: _kTileSize,
            child: CachedNetworkImage(
              imageUrl: _tileUrl(z, wrappedX, ty),
              fit: BoxFit.fill,
              // A flat plate rather than a spinner: tiles are usually already
              // on disk, and a spinner flashing for one frame on every row
              // reads as jank.
              placeholder: (_, __) => Container(color: AppColors.greyE5),
              errorWidget: (_, __, ___) => Container(color: AppColors.greyE5),
            ),
          ),
        );
      }
    }

    if (tiles.isEmpty) return errorWidget;

    return ClipRect(child: Stack(children: tiles));
  }

  static String _tileUrl(int z, int x, int y) => OsmConfig.tileUrlTemplate
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
}

/// A teardrop pin drawn in Flutter rather than fetched as part of the image.
///
/// The Static API used to burn the marker into the picture it returned. Tiles
/// carry no marker, so it is drawn on top — which is strictly better: the same
/// cached tile can back a pin of any colour.
class _Pin extends StatelessWidget {
  const _Pin({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      // Lift so the pin's tip, not its centre, marks the coordinate.
      offset: Offset(0, -size / 2),
      child: Icon(
        Icons.location_on,
        color: color,
        size: size,
        shadows: const [
          Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

/// Required OSM attribution. Small, but present on every rendered map.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: Colors.white.withValues(alpha: 0.7),
        child: Text(
          OsmConfig.attribution,
          style: const TextStyle(fontSize: 7, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
