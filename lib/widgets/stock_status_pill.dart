import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// The In stock / Out of stock pill, shared by the product, grocery and food
/// owner variant sheets and by the product cards themselves.
///
/// Read-only by default (customer surfaces already rendered a pill like this).
/// Pass [onToggle] on owner surfaces and the pill becomes the tap target for
/// the manual out-of-stock flag — it grows a swap affordance and swaps its dot
/// for a spinner while [busy].
///
/// [onToggle] receives the value to WRITE (`true` = mark out of stock), so the
/// caller never has to re-derive the inversion.
///
/// **Driven by `isOutOfStock` alone** — deliberately NOT combined with
/// `totalStock`. Quantity is not maintained across these catalogues (rows come
/// back with `totalStock: 0` while the merchant has never flagged anything), so
/// folding it in marked every product sold out. The manual flag is the single
/// source of truth for this badge.
class StockStatusPill extends StatelessWidget {
  /// `isOutOfStock == false`. Renders the red pill when false.
  final bool inStock;

  /// Owner mode. Null keeps the pill purely informational.
  final Future<void> Function(bool markOutOfStock)? onToggle;

  /// Shows a spinner and swallows taps while the PATCH is in flight.
  final bool busy;

  /// Renders the badge for sitting ON a product photo instead of on a white
  /// panel: a SOLID fill with white text and a drop shadow.
  ///
  /// The default pill is a 10%-alpha tint with a hairline border, which is
  /// legible on the card's white detail area and disappears over a photograph —
  /// exactly where a merchant scanning a rail looks first.
  final bool onImage;

  const StockStatusPill({
    super.key,
    required this.inStock,
    this.onToggle,
    this.busy = false,
    this.onImage = false,
  });

  /// Blur behind the frosted in-stock badge. Small on purpose — see the note
  /// on [_glassify] about how many of these end up on screen at once.
  static const double _glassBlur = 6;

  /// Corner radius, shared by the pill, its clip and its border. A
  /// [BackdropFilter] must be clipped to the shape it fills or the blur bleeds
  /// past the corners.
  static const double _radius = 20;

  /// Lift for a badge sitting on a photo, so its edge survives a busy image.
  /// Applied OUTSIDE the clip on the glass variant — a [ClipRRect] crops its
  /// child, taking any shadow declared within it along with everything else.
  static const List<BoxShadow> _lift = [
    BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.green7F : AppColors.redB4;
    final interactive = onToggle != null;
    final currentFlag = !inStock;
    // Frosted only for the IN-STOCK badge on a photo. Out of stock stays a
    // solid slab: it is the exception the merchant is scanning for, and glass
    // is a quiet treatment — the whole point of it here is that the common,
    // uninteresting state stops shouting over the product photo.
    final glass = onImage && inStock;
    // Over a photo the dot and label go white — against the solid red slab, and
    // against the tinted glass, which is dark enough to carry white. On a white
    // panel they carry the status colour themselves.
    final foreground = onImage ? AppColors.white : color;

    Widget pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: onImage ? 7 : 8,
        vertical: onImage ? 3 : 4,
      ),
      decoration: BoxDecoration(
        // Glass: the colour is a TINT over whatever the blur sampled, so it
        // sits well below the solid badge's alpha. Too opaque and it stops
        // reading as glass and starts reading as a flat green chip.
        color: glass
            ? color.withValues(alpha: 0.42)
            : (onImage ? color : color.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(_radius),
        // A white rim is what gives frosted glass its edge over an arbitrary
        // photo — without it the badge dissolves into a light background.
        border: glass
            ? Border.all(color: AppColors.white.withValues(alpha: 0.55))
            : (onImage
                ? null
                : Border.all(color: color.withValues(alpha: 0.30))),
        // Glass takes its lift from [_glassify] instead: a ClipRRect crops its
        // child, so a shadow declared in here would be clipped away with
        // everything else past the rounded edge.
        boxShadow: (onImage && !glass) ? _lift : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                  strokeWidth: 1.6, color: foreground),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          CustomText(
            inStock ? 'In stock' : 'Out of stock',
            fontSize: onImage ? 10 : SizeConfig.small11,
            fontWeight: onImage ? FontWeight.w800 : FontWeight.w700,
            color: foreground,
          ),
          if (interactive) ...[
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 13, color: foreground),
          ],
        ],
      ),
    );

    if (glass) pill = _glassify(pill);

    if (!interactive) return pill;

    return InkWell(
      onTap: busy ? null : () => onToggle!(!currentFlag),
      borderRadius: BorderRadius.circular(_radius),
      child: Opacity(opacity: busy ? 0.6 : 1, child: pill),
    );
  }

  /// Frosts [pill] by blurring what is painted behind it — the product photo.
  ///
  /// The [ClipRRect] is not optional: a [BackdropFilter] samples the whole
  /// layer unless it is clipped, so without it the blur would spill across the
  /// entire card instead of staying inside the badge.
  ///
  /// ## On the cost
  ///
  /// A BackdropFilter forces a `saveLayer` and re-samples the pixels beneath it
  /// every frame, and this badge is on EVERY card — a scrolling rail can have a
  /// dozen on screen at once. `discover_glass.dart` documents the same trade-off
  /// and a device-dependent Android GPU bug that smeared text under exactly
  /// this shape. Two things keep it survivable here: the sigma is low (6 against
  /// Discover's 10), and each filter is clipped to a badge a few dozen pixels
  /// wide rather than a full-width panel.
  ///
  /// If smearing or a frame-time cliff shows up on real devices, the fix is to
  /// drop this wrapper and let the tinted fill carry the look on its own — the
  /// colour and rim above already do most of the work — not to tune the sigma.
  Widget _glassify(Widget pill) {
    // Shadow OUTSIDE the clip — see the note on [_lift].
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: _lift,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: _glassBlur, sigmaY: _glassBlur),
          child: pill,
        ),
      ),
    );
  }
}
