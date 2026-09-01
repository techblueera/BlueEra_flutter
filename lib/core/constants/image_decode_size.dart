import 'package:flutter/widgets.dart';

/// How wide an image should be **decoded**, given the slot it will be drawn in.
///
/// `CachedNetworkImage` (and `Image.network` under it) decodes to the source
/// file's full pixel dimensions unless told otherwise, and holds that bitmap in
/// the image cache. A 1080x1350 post photo is ~5.8 MB of RAM whether it is shown
/// at 1080px or at 40px — and Flutter's default image cache is 100 MB / 1000
/// entries, so a feed scroll fills it with full-resolution decodes of pictures
/// nobody is looking at any more. That is the single largest cause of scroll
/// jank and low-memory kills on mid-range Android devices in an image feed:
/// every extra megabyte is GPU upload bandwidth and GC pressure on the frame
/// that first paints it.
///
/// Passing [memCacheWidth] makes the decoder resample while decoding, so the
/// bitmap that reaches memory is already the size it will be painted at.
///
/// [logicalWidth] is the widget-space width of the slot. The result is that in
/// **device pixels**, which is what the decoder wants — decoding to logical
/// width would give a visibly soft image on any screen above 1x.
///
/// Returns null (decode at source size) when the slot has no usable width, so a
/// caller inside an unbounded box degrades to today's behaviour rather than to a
/// 1-pixel thumbnail.
int? decodeWidthFor(BuildContext context, double logicalWidth) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
  final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
  return _cap(logicalWidth * ratio);
}

/// [decodeWidthFor] for callers that already know the device-pixel width, or
/// that have no [BuildContext] to read a ratio from.
int? decodeWidthForPixels(double pixelWidth) {
  if (!pixelWidth.isFinite || pixelWidth <= 0) return null;
  return _cap(pixelWidth);
}

/// Never ask for more than a phone screen's worth of pixels.
///
/// Upper bound: a source image smaller than the request is NOT upscaled — the
/// decoder only ever resamples down — so a generous cap costs nothing on small
/// images while stopping an oversized slot (a full-bleed hero on a tablet) from
/// asking for a 4000px decode.
///
/// Lower bound: below this the resampling saves less than it costs in
/// sharpness, and tiny decodes look soft on high-density screens.
int _cap(double pixels) => pixels.round().clamp(64, 1440);
