import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Which face of the card a frame is asking for.
enum AadhaarSide { front, back }

/// A capture slot shaped like the card it wants a photo of.
///
/// Deliberately NOT another upload button — a button-shaped row asks the rider
/// to read which side we mean, and front vs back is a SPATIAL distinction. So
/// the slot draws it: an empty frame is a miniature of that face of the card —
/// photo box, name rules and the 4-4-4 number on the front; address rules and
/// the QR square on the back — inside crop-mark brackets at the exact ID-1 /
/// CR80 ratio the cropper will produce
/// ([CommonImageUploadTile.documentCropAspectRatio]). The empty state is
/// therefore a true preview of the finished shot, and it reads without the
/// label, which matters: several of the languages the app ships fall back to
/// English for these strings.
///
/// Filled, the photo replaces the schematic behind the same brackets, the
/// frame takes the primary colour and a check badge appears — so the pair
/// reads at a glance as "one done, one to go".
class AadhaarCaptureFrame extends StatelessWidget {
  final AadhaarSide side;

  /// The picked photo. Observed, so the frame flips itself.
  final Rxn<File> imageFile;

  /// Open the picker (empty slot, or the retake badge on a filled one).
  final VoidCallback onPick;

  /// Open the full-screen viewer. Tapping a filled frame.
  final VoidCallback onView;

  /// Short caption printed inside the frame — "Aadhar Front" / "Aadhar Back".
  final String label;

  const AadhaarCaptureFrame({
    super.key,
    required this.side,
    required this.imageFile,
    required this.onPick,
    required this.onView,
    required this.label,
  });

  /// Read off the cropper's own constant rather than restated here, so the
  /// preview and the crop window can never drift apart — the empty frame is
  /// the shape the rider will be asked to fill.
  static final double _cardRatio =
      CommonImageUploadTile.documentCropAspectRatio.ratio;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = imageFile.value;
      final filled = file != null;

      return Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: filled ? onView : onPick,
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _cardRatio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? AppColors.primaryColor : AppColors.greyE5,
                  width: filled ? 1.4 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Schematic → photo. Cross-faded rather than swapped so the
                  // card appears to develop in place.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: filled
                        ? Image.file(
                            file,
                            key: ValueKey(file.path),
                            fit: BoxFit.cover,
                          )
                        : CustomPaint(
                            key: ValueKey('schematic_${side.name}'),
                            painter: _AadhaarSchematicPainter(
                              side: side,
                              ink: AppColors.greyE5,
                            ),
                          ),
                  ),

                  // Crop marks. Kept on the filled state too — they are what
                  // says "the whole card must sit inside this".
                  CustomPaint(
                    painter: _CropMarksPainter(
                      color: filled
                          ? AppColors.primaryColor
                          : AppColors.coloGreyText.withValues(alpha: 0.55),
                    ),
                  ),

                  // Caption, printed on the card rather than under it.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _caption(filled),
                  ),

                  Positioned(top: 5, right: 5, child: _badge(filled)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _caption(bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        // Over a photo the strip has to carry its own contrast; over the
        // schematic it should stay quiet.
        color: filled
            ? AppColors.black.withValues(alpha: 0.55)
            : AppColors.white.withValues(alpha: 0.9),
      ),
      child: CustomText(
        label.toUpperCase(),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: filled ? AppColors.white : AppColors.coloGreyText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Camera on an empty slot; check + retake on a filled one. The badge is the
  /// only tap target that differs from the frame itself.
  Widget _badge(bool filled) {
    if (!filled) {
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.photo_camera_rounded,
          size: 13,
          color: AppColors.white,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.green00,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 12, color: AppColors.white),
        ),
        const SizedBox(width: 4),
        // Retake rather than remove: an empty slot is never what the rider
        // wants next — they want a better photo.
        InkWell(
          onTap: onPick,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.refresh_rounded, size: 12, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

/// Draws the miniature card face. Everything is a fraction of the canvas, so
/// the schematic holds its proportions at any slot width.
class _AadhaarSchematicPainter extends CustomPainter {
  final AadhaarSide side;
  final Color ink;

  _AadhaarSchematicPainter({required this.side, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = ink;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void rule(double x, double y, double len, {double thickness = 0.055}) {
      final barHeight = h * thickness;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * y, w * len, barHeight),
          Radius.circular(barHeight / 2),
        ),
        fill,
      );
    }

    if (side == AadhaarSide.front) {
      // Portrait box, top-left — the single most recognisable thing on the
      // front of the card.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.09, h * 0.17, w * 0.20, h * 0.40),
          const Radius.circular(2),
        ),
        stroke,
      );
      // Name / DOB / gender, shortening down the block.
      rule(0.35, 0.20, 0.48);
      rule(0.35, 0.33, 0.36);
      rule(0.35, 0.46, 0.24);
      // The 4-4-4 number across the foot.
      for (var i = 0; i < 3; i++) {
        rule(0.09 + i * 0.24, 0.70, 0.18, thickness: 0.07);
      }
    } else {
      // Address block, left; QR, right — the back's own arrangement.
      rule(0.09, 0.20, 0.42);
      rule(0.09, 0.33, 0.48);
      rule(0.09, 0.46, 0.38);
      rule(0.09, 0.59, 0.30);
      final qr = Rect.fromLTWH(w * 0.65, h * 0.22, w * 0.26, h * 0.42);
      canvas.drawRRect(
        RRect.fromRectAndRadius(qr, const Radius.circular(2)),
        stroke,
      );
      // Three finder squares — enough to read as a QR at 26px wide.
      final cell = qr.width * 0.26;
      for (final offset in [
        Offset(qr.left + cell * 0.35, qr.top + cell * 0.35),
        Offset(qr.right - cell * 1.35, qr.top + cell * 0.35),
        Offset(qr.left + cell * 0.35, qr.bottom - cell * 1.35),
      ]) {
        canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cell, cell), fill);
      }
    }
  }

  @override
  bool shouldRepaint(_AadhaarSchematicPainter old) =>
      old.side != side || old.ink != ink;
}

/// Four corner brackets — the viewfinder marks that say where the card's own
/// corners have to land.
class _CropMarksPainter extends CustomPainter {
  final Color color;

  _CropMarksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final arm = size.width * 0.13;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;

    void corner(Offset pivot, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(pivot.dx + dx * arm, pivot.dy)
          ..lineTo(pivot.dx, pivot.dy)
          ..lineTo(pivot.dx, pivot.dy + dy * arm),
        paint,
      );
    }

    corner(Offset(l, t), 1, 1);
    corner(Offset(r, t), -1, 1);
    corner(Offset(l, b), 1, -1);
    corner(Offset(r, b), -1, -1);
  }

  @override
  bool shouldRepaint(_CropMarksPainter old) => old.color != color;
}
