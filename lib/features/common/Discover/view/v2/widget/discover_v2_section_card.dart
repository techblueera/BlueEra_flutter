import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// The one surface every block on `DiscoverScreenV2` sits on.
///
/// Glassmorphic, the same recipe v1 paints: a translucent white wash behind a
/// real [BackdropFilter], inside a solid white rim. Content scrolling under a
/// card blurs through it, which is the whole effect — a solid fill would let
/// the page scroll behind an opaque rectangle and lose it.
///
/// The surface itself is read from [DiscoverSurfaceTheme], the scope the
/// screen installs above the scroll view, so the tokens live in ONE place and
/// the shimmer, the folder tiles and these cards cannot drift apart. This is
/// [DiscoverGlassPanel] plus the heading row the v2 sections need.
///
/// **Two things the blur demands of the page around it**, both handled by
/// `DiscoverScreenV2`:
///
///  * overscroll must not STRETCH — Android 12+ implements stretch by moving
///    the scroll content into its own layer, and a `BackdropFilter` can only
///    sample what is inside its enclosing layer, so every panel goes dark for
///    the length of a drag. Hence [DiscoverGlassScrollBehavior].
///  * the shadow has to sit OUTSIDE the clip, or the [ClipRRect] crops it away
///    with everything else past the rounded edge.
class DiscoverV2Card extends StatelessWidget {
  const DiscoverV2Card({
    super.key,
    required this.child,
    this.title,
    this.trailingLabel,
    this.onTrailingTap,
    this.padding = const EdgeInsets.all(14),
  });

  /// Heading drawn at the top of the card. Omit for a card that is pure
  /// content (the QR pair).
  final String? title;

  /// Optional right-aligned action beside [title] — "View All" in the design.
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  final EdgeInsets padding;
  final Widget child;

  // ── The v2 surface ────────────────────────────────────────────────────────
  //
  // The spec, verbatim: fill `#FFFFFF99`, border `#FFFFFF` at 1.5, blur 20,
  // shadow `#15171814` blur 10 / spread 0 / x0 / y1.
  //
  // **Alpha comes FIRST in a Dart colour literal.** Both values above are
  // written the CSS way (`#RRGGBBAA`), so they invert to `0xAARRGGBB`:
  // `#FFFFFF99` → `0x99FFFFFF`, and `#15171814` → `0x14151718`. Getting this
  // backwards produces a near-transparent blue-grey instead of a white wash,
  // which is exactly what an earlier pass at this page shipped.
  static const Color fill = Color(0x99FFFFFF);
  static const Color stroke = Color(0xFFFFFFFF);
  static const double strokeWidth = 1.5;

  /// 20, not the 5 this started at. A heavy sigma is what makes the panel read
  /// as frosted rather than merely semi-transparent — at 5 the content behind
  /// it stayed identifiable and the card looked like a rendering fault.
  static const double blur = 20;

  static const double radius = 10;

  /// `#151718` at 8% (`0x14` = 20/255), blur 10, spread 0, y+1. One soft lift,
  /// not the stacked pair in [kDiscoverGlassShadow], which doubles the
  /// darkness at a panel's edge.
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x14151718),
      blurRadius: 0,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DiscoverGlassPanel(
      radius: DiscoverSurfaceTheme.radiusOf(context),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            _header(),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _header() {
    final action = trailingLabel;
    return Row(
      children: [
        Expanded(
          child: CustomText(
            title!,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTrailingTap,
            // Padding rather than a bare Text: "View All" is 7 characters of
            // tap target, which is under the 48dp minimum on every phone.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: CustomText(
                action,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
