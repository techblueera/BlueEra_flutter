import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A category / service icon whose path can be anything the backend sends: a
/// bundled asset, a remote SVG, or a remote raster.
///
/// ## Why this exists
///
/// The call sites each rolled their own routing, and three of them sent EVERY
/// network URL to [SvgPicture.network] — PNGs and JPEGs included. The SVG
/// decoder parses its input as XML, so a raster body threw
/// `XmlParserException: ">" expected` out of the loader's isolate on a
/// background future, which surfaces as a fatal rather than a broken image.
///
/// A `.svg` URL is not proof either: an expired link or a 404 answers with an
/// HTML error page, which is *almost* XML and fails the same way a few
/// characters in. So the SVG branch also carries an [SvgPicture.errorBuilder]
/// — without one, flutter_svg has nowhere to put the failure.
///
/// Every branch ends at [fallbackAsset] rather than at nothing, so a bad path
/// costs an icon, never the screen.
class RemoteIconImage extends StatelessWidget {
  const RemoteIconImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    String? fallbackAsset,
    this.showLoader = false,
  }) : _fallbackAsset = fallbackAsset;

  /// An asset path, an http(s) URL, or null/empty for "nothing to show".
  final String? path;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Drawn when [path] is empty, unreachable, or undecodable. Defaults to the
  /// shared placeholder artwork.
  final String? _fallbackAsset;

  /// Whether a remote fetch shows a spinner. Off by default: these icons are
  /// small and usually sit in a row of others, where spinners read as noise.
  final bool showLoader;

  String get _fallback => _fallbackAsset ?? AppIconAssets.place_holder_image;

  @override
  Widget build(BuildContext context) {
    final raw = path?.trim() ?? '';
    if (raw.isEmpty) return _placeholder();

    if (!isNetworkImage(raw)) {
      // Bundled: LocalAssets already tells .svg from raster by extension.
      return LocalAssets(
        imagePath: raw,
        width: width,
        height: height,
        boxFix: fit,
      );
    }

    if (raw.toLowerCase().split('?').first.endsWith('.svg')) {
      return SvgPicture.network(
        raw,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => _loading(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: raw,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _loading(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => LocalAssets(
        imagePath: _fallback,
        width: width,
        height: height,
        boxFix: fit,
      );

  Widget _loading() => showLoader
      ? SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : SizedBox(width: width, height: height);
}
