import 'package:flutter/material.dart';

/// The green "N% Off / On All Items" sticker on a self-pickup cart's store
/// header (grocery, food, product, manufacturer, pharmacy).
///
/// Shared, not copied: this used to be a private `_DiscountRibbon` duplicated
/// verbatim in all five cart screens, so a fix had to be made five times.
///
/// **Responsive.** The store header is `[logo] [name + pills] [ribbon] [✕]`,
/// where the name is `Expanded` — so the ribbon always takes its intrinsic
/// width and the *name* is what gives way. At a fixed size the ribbon therefore
/// dominated the row on narrow screens and squeezed long store names to an
/// ellipsis. It now scales down with screen width, using the same baseline as
/// [StickyCategoryHeaderDelegate]: full size at >=390dp, easing to 80% on the
/// narrowest phones.
class DiscountRibbon extends StatelessWidget {
  /// Average discount across the store's items, as a percentage. Values above
  /// 99 are clamped; whole numbers drop the decimal ("20%", not "20.0%").
  final double percent;

  /// Trailing gap before the ✕. Callers historically used 4 (grocery, pharmacy)
  /// or 10 (food, product, manufacturer) — kept as a parameter so consolidating
  /// didn't shift any existing layout.
  final EdgeInsetsGeometry padding;

  const DiscountRibbon({
    super.key,
    required this.percent,
    this.padding = const EdgeInsets.only(right: 4),
  });

  /// Width at which the ribbon renders at full size. Below it everything
  /// scales; above it nothing changes.
  static const double _baselineWidth = 390;
  static const double _minScale = 0.8;

  String get _label {
    final clamped = percent > 99 ? 99 : percent;
    final isWhole = clamped == clamped.roundToDouble();
    return isWhole ? clamped.toStringAsFixed(0) : clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final double scale = (MediaQuery.of(context).size.width / _baselineWidth)
        .clamp(_minScale, 1.0);

    return Padding(
      padding: padding,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.4),
            radius: 1.1,
            colors: [Color(0xFFB5D147), Color(0xFF0D8A47)],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(10 * scale),
          // The yellow ring frames it like a sticker; below ~1.5 it stops
          // reading as a ring at all, so it scales less than the rest.
          border: Border.all(
            color: const Color(0xFFFFD83D),
            width: (2 * scale).clamp(1.5, 2.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15A352).withValues(alpha: 0.28),
              blurRadius: 10 * scale,
              offset: Offset(0, 3 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_label%',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 4 * scale),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    'Off',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            Text(
              'On All Items',
              style: TextStyle(
                fontSize: 9 * scale,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
