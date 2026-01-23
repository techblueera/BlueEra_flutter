import 'dart:ui' as ui;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    const double iconTargetWidth = 80; // How big you want the SVG to look

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

    final double bubbleOffsetX = (totalWidth - bubbleWidth) / 2;

    final Paint bubblePaint = Paint()..color = const Color(0xFFE0E9EA)..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = AppColors.primaryColor..style = PaintingStyle.stroke..strokeWidth = 3.0;

    final RRect bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleOffsetX, 0, bubbleWidth, bubbleHeight),
      const Radius.circular(10),
    );

    canvas.drawRRect(bubbleRect, bubblePaint);
    canvas.drawRRect(bubbleRect, borderPaint);

    // Draw Title
    TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: SizeConfig.title,
            fontWeight: FontWeight.w600),

      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(bubbleOffsetX + (bubbleWidth - titlePainter.width) / 2, 15));


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