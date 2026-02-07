import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class TooltipGenerator {

  /// Generates a composite image: Tooltip Bubble (Top) + SVG Icon (Bottom)
  static Future<Uint8List> createTooltipWithSvg({
    required String title,
    required String svgAssetPath, // e.g., 'assets/images/marker.svg'
  }) async {

    // 1. Configuration
    const double bubbleWidth = 250;
    const double bubbleHeight = 90;
    const double gap = 10; // Space between bubble and icon
    const double iconTargetWidth = 75; // How big you want the SVG to look

    // 2. Load and Rasterize the SVG
    final ui.Image iconImage = await _rasterizeSvg(svgAssetPath, iconTargetWidth);

    // Calculate total dimensions
    final double totalHeight = bubbleHeight + gap + iconImage.height;
    final double totalWidth = (iconImage.width > bubbleWidth) ? iconImage.width.toDouble() : bubbleWidth;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // -----------------------------------------------------------------------
    // STEP A: Draw the Text Bubble
    // -----------------------------------------------------------------------

    // final double bubbleOffsetX = (totalWidth - bubbleWidth) / 2;
    //
    // final Paint bubblePaint = Paint()..color = const Color(0xFFE0E9EA)..style = PaintingStyle.fill;
    // final Paint borderPaint = Paint()..color = AppColors.primaryColor..style = PaintingStyle.stroke..strokeWidth = 3.0;
    //
    // final RRect bubbleRect = RRect.fromRectAndRadius(
    //   Rect.fromLTWH(bubbleOffsetX, 0, bubbleWidth, bubbleHeight),
    //   const Radius.circular(10),
    // );
    //
    // canvas.drawRRect(bubbleRect, bubblePaint);
    // canvas.drawRRect(bubbleRect, borderPaint);
    //
    // // Draw Title
    // TextPainter titlePainter = TextPainter(
    //   text: TextSpan(
    //     text: title,
    //     style: TextStyle(
    //         color: AppColors.primaryColor,
    //         fontSize: SizeConfig.title,
    //         fontWeight: FontWeight.w600),
    //
    //   ),
    //   textAlign: TextAlign.center,
    //   textDirection: TextDirection.ltr,
    // );
    // titlePainter.layout();
    // titlePainter.paint(canvas, Offset(bubbleOffsetX + (bubbleWidth - titlePainter.width) / 2, 15));


    // -----------------------------------------------------------------------
    // STEP B: Draw the SVG Image below
    // -----------------------------------------------------------------------

    final double iconOffsetX = (totalWidth - iconImage.width) / 2;
    final double iconOffsetY = bubbleHeight + gap;

    canvas.drawImage(iconImage, Offset(iconOffsetX, iconOffsetY), Paint());

    // -----------------------------------------------------------------------
    // STEP C: Convert to Bytes
    // -----------------------------------------------------------------------
    final ui.Image finalImage = await pictureRecorder.endRecording().toImage(
      totalWidth.toInt(),
      totalHeight.toInt(),
    );
    final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Helper to convert SVG asset to a dart:ui Image
  static Future<ui.Image> _rasterizeSvg(String assetPath, double width) async {
    // Load the SVG string
    final String svgString = await rootBundle.loadString(assetPath);

    // Load standard SVG
    final PictureInfo pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);

    // Calculate height to keep aspect ratio
    final double aspectRatio = pictureInfo.size.width / pictureInfo.size.height;
    final double height = width / aspectRatio;

    // Draw to canvas to resize
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Scale it
    canvas.scale(width / pictureInfo.size.width);
    canvas.drawPicture(pictureInfo.picture);

    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }
}


class TooltipGeneratorOnlyLocationIcon {

  /// Generates ONLY SVG icon as PNG bytes
  static Future<Uint8List> createIconOnly({
    required String svgAssetPath,
    double iconTargetWidth = 80,
  }) async {
    final ui.Image iconImage =
    await _rasterizeSvg(svgAssetPath, iconTargetWidth);

    final ByteData? byteData =
    await iconImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Convert SVG asset → ui.Image
  static Future<ui.Image> _rasterizeSvg(
      String assetPath,
      double width,
      ) async {
    final String svgString = await rootBundle.loadString(assetPath);

    final PictureInfo pictureInfo =
    await vg.loadPicture(SvgStringLoader(svgString), null);

    final double aspectRatio =
        pictureInfo.size.width / pictureInfo.size.height;
    final double height = width / aspectRatio;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.scale(width / pictureInfo.size.width);
    canvas.drawPicture(pictureInfo.picture);

    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }
}
class ProfileLocationMarkerGenerator {
  static Future<Uint8List> createMarker({
    required String imageUrl,
    double imageSize = 80,
    double borderWidth = 5,
    double dotRadius = 6,
    Color borderColor = const Color(0xFF1E88E5), // Blue
    Color dotColor = const Color(0xFF1E88E5),
  }) async {
    final double totalWidth = imageSize + borderWidth * 2;
    final double canvasHeight =
        totalWidth + dotRadius * 2 + 8; // space for dot

    // 1️⃣ Download image
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Uint8List bytes = response.bodyBytes;

    // 2️⃣ Decode image
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: imageSize.toInt(),
      targetHeight: imageSize.toInt(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    // 3️⃣ Canvas setup
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint paint = Paint()..isAntiAlias = true;
    final Offset imageCenter =
    Offset(totalWidth / 2, totalWidth / 2);

    // 🔵 Border
    paint.color = borderColor;
    canvas.drawCircle(
      imageCenter,
      imageSize / 2 + borderWidth,
      paint,
    );

    // 👤 Clip image circle
    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(
        center: imageCenter,
        radius: imageSize / 2,
      ));
    canvas.save();
    canvas.clipPath(clipPath);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      Rect.fromCenter(
        center: imageCenter,
        width: imageSize,
        height: imageSize,
      ),
      paint,
    );
    canvas.restore();

    // 🔵 Location dot (bottom center)
    final Offset dotCenter = Offset(
      totalWidth / 2,
      totalWidth + dotRadius + 4,
    );

    paint.color = dotColor;
    canvas.drawCircle(dotCenter, dotRadius, paint);

    // 4️⃣ Convert to PNG
    final ui.Image finalImage = await recorder
        .endRecording()
        .toImage(
      totalWidth.toInt(),
      canvasHeight.toInt(),
    );

    final ByteData? data =
    await finalImage.toByteData(format: ui.ImageByteFormat.png);

    return data!.buffer.asUint8List();
  }
}
