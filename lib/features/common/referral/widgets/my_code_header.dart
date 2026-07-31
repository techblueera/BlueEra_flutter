import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/widgets/referral_share_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Code pill displayed in the dashboard's AppBar (right action slot).
/// Mirrors the capsule in `assets/overview_screen.png`:
///
///   [ ADF8ZD ┊ 📋 ┊ ↗ ]
///
/// Light primary-blue tinted capsule with a primary-blue border. The
/// code text reads in bold blue, followed by copy and share actions
/// separated by **dashed** vertical hairlines. Both action icons use
/// [AppColors.secondaryTextColor] so they read as quiet controls
/// against the tinted background. The share glyph is the brand
/// `reel_share` SVG re-used across the app.
class MyCodeHeader extends StatelessWidget {
  final String code;
  final EdgeInsetsGeometry? margin;

  const MyCodeHeader({
    super.key,
    required this.code,
    this.margin,
  });

  Future<void> _copy() async {
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      AppStrings.copiedLabel.tr,
      AppStrings.referralCodeCopiedToClipboard.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.white,
      colorText: AppColors.mainTextColor,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
    );
  }

  /// Builds the branded referral poster off-screen and shares it as an
  /// image, with the full download/referral text as the share body.
  /// Needs a [BuildContext] to host the off-screen overlay.
  Future<void> _share(BuildContext context) async {
    if (code.isEmpty) return;
    await ReferralShareCard.buildAndShare(context, code: code);
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = code.isNotEmpty;
    final divider = _DashedVerticalDivider(
      height: 16,
      color: AppColors.primaryColor.withValues(alpha: 0.45),
    );
    return Padding(
      padding: margin?.resolve(Directionality.of(context)) ?? EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          // Action background uses the primary blue at 10% opacity so
          // the capsule reads as a subtle tinted chip on the
          // chat-default texture rather than a hard white block.
          color: AppColors.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              hasCode ? code.toUpperCase() : '------',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
              letterSpacing: 0.5,
            ),
            const SizedBox(width: 8),
            divider,
            const SizedBox(width: 8),
            _IconAction(
              materialIcon: Icons.copy_rounded,
              onTap: hasCode ? _copy : null,
              tooltip: AppStrings.copyCode.tr,
            ),
            const SizedBox(width: 8),
            divider,
            const SizedBox(width: 8),
            _IconAction(
              assetPath: AppIconAssets.reelShare,
              onTap: hasCode ? () => _share(context) : null,
              tooltip: AppStrings.shareCode.tr,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact icon button used inside the code pill. Accepts either a
/// Material [IconData] or an SVG [assetPath] (rendered via
/// [LocalAssets]). Both render in [AppColors.secondaryTextColor] and
/// dim to 40 % opacity when no `onTap` is provided.
class _IconAction extends StatelessWidget {
  final IconData? materialIcon;
  final String? assetPath;
  final VoidCallback? onTap;
  final String tooltip;

  const _IconAction({
    this.materialIcon,
    this.assetPath,
    required this.onTap,
    required this.tooltip,
  }) : assert(materialIcon != null || assetPath != null);

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? AppColors.secondaryTextColor.withValues(alpha: 0.4)
        : AppColors.secondaryTextColor;
    final glyph = assetPath != null
        ? LocalAssets(
            imagePath: assetPath!,
            imgColor: color,
            height: 16,
            width: 16,
          )
        : Icon(materialIcon, size: 16, color: color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Tooltip(message: tooltip, child: glyph),
      ),
    );
  }
}

/// Short dashed vertical line used between the code and each action.
class _DashedVerticalDivider extends StatelessWidget {
  final double height;
  final Color color;
  const _DashedVerticalDivider({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashLength = 2.5;
  static const double _dashGap = 2;

  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final centerX = size.width / 2;
    double y = 0;
    while (y < size.height) {
      final end = (y + _dashLength).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(centerX, y), Offset(centerX, end), paint);
      y += _dashLength + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color;
}
