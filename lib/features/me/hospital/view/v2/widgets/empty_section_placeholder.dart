import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Mirrors the medical-v2 gallery empty state: a preview image rendered
/// in black & white with a dark overlay and an add-content CTA in the
/// center. Used across the hospital "me" tabs whenever a section has
/// no data yet (management, gallery, OPD, IPD, other facilities…).
class EmptySectionPlaceholder extends StatelessWidget {
  /// Local asset path used as the greyed-out preview backdrop.
  final String imageAsset;

  /// CTA label rendered over the overlay (e.g. "Add Photos").
  final String ctaLabel;

  /// Icon shown above the CTA label.
  final IconData ctaIcon;

  /// Tap handler — usually navigates to the section's edit screen.
  final VoidCallback onTap;

  /// Aspect ratio of the placeholder card. Defaults to 16:10 (matches
  /// the medical gallery), but caller can override (e.g. 16:9 banner,
  /// 1:1 square thumb).
  final double aspectRatio;

  const EmptySectionPlaceholder({
    super.key,
    required this.imageAsset,
    required this.ctaLabel,
    required this.onTap,
    this.ctaIcon = Icons.add_photo_alternate_outlined,
    this.aspectRatio = 16 / 10,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
              ),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ctaIcon, color: Colors.white, size: 32),
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      ctaLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
