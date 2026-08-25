import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The Discover landing page's glass surface — the one recipe every panel on
/// that page paints itself with (the folder tiles, the header banner, the
/// recent-orders rail).
///
/// This is NOT the app-wide glass in `widgets/glass_surface.dart`. That one is
/// a white wash with no blur, for cards sitting on the background banner
/// elsewhere in the app. Discover's landing grid is a different surface with
/// different reasons behind it, described below, and the two must not be
/// swapped for each other.
///
/// It lives here because the values were being copied per call site — the tile
/// and the banner each carried their own `Color(0x1F101922)` and `blur: 10`,
/// which is exactly how two panels on one page end up a shade apart after
/// someone tunes one of them.

/// Fill: a dark ink at low alpha, NOT a white wash.
///
/// The default background ([AppImageAssets.chatBgBlueShade]) is a very PALE
/// blue, and white-on-near-white leaves the panels dissolving into the page.
/// #101922 sits a step DARKER than the background instead, which is what gives
/// every panel an edge without giving it a colour of its own.
///
/// Held at 12%, not the 20% this started at. At 20% the ink stopped reading as
/// a tint over the background and started reading as a grey card painted on top
/// of it — the panels went heavy and the pale blue no longer came through. The
/// blur does most of the work; the fill only has to separate panel from page.
const Color kDiscoverGlassFill = Color(0x1F101922);

/// Rim. Solid white at 1px — the panel is darker than the page it sits on, and
/// the white edge is what gives it a shape.
const Color kDiscoverGlassBorder = Colors.white;

/// Lift, in the same ink as the fill so the shadow belongs to the panel rather
/// than greying the background under it.
const List<BoxShadow> kDiscoverGlassShadow = [
  BoxShadow(color: Color(0x1F101922), blurRadius: 14, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x14101922), blurRadius: 4, offset: Offset(0, 1)),
];

/// ## This is a real [BackdropFilter], against the standing advice on this page
///
/// `glass_surface.dart` and `_DiscoverHeaderDelegate` both say not to blur
/// here, and they are not stale: a BackdropFilter forces a `saveLayer` and
/// re-samples what is painted beneath it every frame. The landing grid is ~14
/// tiles inside a scroll view, so that is ~14 sampled layers, and it is the
/// same shape as the setup that smeared text on this page twice before — a
/// device-dependent Android GPU/driver bug that does NOT reproduce on most dev
/// hardware.
///
/// It is here because the design calls for true frosted glass and was specified
/// with this radius. Two things make it survivable where the header did not:
/// each filter is CLIPPED to its own panel (a small, bounded region rather than
/// the full width of a pinned header), and what it samples is the static page
/// background, not the live feed scrolling underneath.
///
/// Every new caller adds one more sampled layer, so this is not free to sprinkle
/// around. If smearing or a frame-time cliff shows up on real devices, the fix
/// is to drop the blur to plain alpha — [kDiscoverGlassFill] already carries the
/// look on its own — not to tune the sigma.
const double kDiscoverGlassBlur = 10;

/// Corner radius, shared by the clip and the fill: a [BackdropFilter] has to be
/// clipped to the panel's own shape, and the two radii must agree or the blur
/// bleeds past the corners.
const double kDiscoverGlassRadius = 26;

/// Plate for a small block sitting ON the glass — an icon slot in a folder, a
/// row in the orders rail.
///
/// A brighter white than the panel under it, so its contents keep a clean base
/// and a group of them reads as separate slots rather than one wash. This is
/// also what lets those blocks carry ordinary DARK text: the panel itself is
/// ink over an unknown background and can't be relied on for contrast, the
/// plate can.
const Color kDiscoverGlassPlateFill = Color(0x8FFFFFFF);

/// Scroll behaviour every scroll view that CONTAINS glass panels has to use.
///
/// ## Why the glass goes dark when you drag
///
/// Android 12+ overscrolls by *stretching the content*: the default
/// [StretchingOverscrollIndicator] wraps the scroll view's children in a clip
/// and a non-identity [Transform] for the duration of the drag. That transform
/// is a layer boundary, and a [BackdropFilter] can only sample what is painted
/// inside its own enclosing layer.
///
/// On this page the background image is a SIBLING of the scroll view, not part
/// of it. So the moment the stretch kicks in, every panel stops sampling the
/// pale blue page and starts sampling an otherwise-empty layer — blurred
/// transparent black, which is why the glass turns dark under your finger and
/// recovers the instant you let go.
///
/// Dropping the indicator keeps the backdrop correct at every scroll offset.
/// Pull-to-refresh still gives the downward drag its own feedback, so the page
/// doesn't lose an affordance; the edges just stop rather than stretching. (A
/// [GlowingOverscrollIndicator] would also be safe — it paints OVER the content
/// instead of transforming it — but the old glow reads as a foreign material
/// against these panels.)
class DiscoverGlassScrollBehavior extends MaterialScrollBehavior {
  const DiscoverGlassScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

/// A panel painted in the Discover glass recipe above.
///
/// Note the shadow sits OUTSIDE the clip: a [ClipRRect] crops its child, so a
/// `boxShadow` declared inside it is clipped away with everything else past the
/// rounded edge.
class DiscoverGlassPanel extends StatelessWidget {
  const DiscoverGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = kDiscoverGlassRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Defaults to the landing grid's radius so a panel lines up with the folder
  /// tiles it sits among.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: kDiscoverGlassShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: kDiscoverGlassBlur,
            sigmaY: kDiscoverGlassBlur,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Translucent, so the panel keeps picking up whatever it sits on
              // — the background is unchanged, only the panel over it is.
              color: kDiscoverGlassFill,
              borderRadius: borderRadius,
              border: Border.all(color: kDiscoverGlassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Per-subtree overrides for the glass tokens above.
///
/// Discover v2 was specified with its own surface — a lighter ink, a solid
/// stroke and a deeper blur — and it shares [DiscoverFolderTile] with v1, so
/// the two looks cannot both live in the constants. A scope keeps v1 exactly as
/// it was: anything that does not find one of these reads the constants.
class DiscoverSurfaceTheme extends InheritedWidget {
  const DiscoverSurfaceTheme({
    super.key,
    required this.fill,
    required this.border,
    required this.blur,
    required this.radius,
    required super.child,
  });

  final Color fill;
  final Color border;
  final double blur;
  final double radius;

  /// v2's surface: `#10192233` over `#DDE2EE`, blurred 20.
  static const DiscoverSurfaceTheme? _none = null;

  static DiscoverSurfaceTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiscoverSurfaceTheme>() ??
      _none;

  static Color fillOf(BuildContext context) =>
      maybeOf(context)?.fill ?? kDiscoverGlassFill;

  static Color borderOf(BuildContext context) =>
      maybeOf(context)?.border ?? kDiscoverGlassBorder;

  static double blurOf(BuildContext context) =>
      maybeOf(context)?.blur ?? kDiscoverGlassBlur;

  static double radiusOf(BuildContext context) =>
      maybeOf(context)?.radius ?? kDiscoverGlassRadius;

  @override
  bool updateShouldNotify(DiscoverSurfaceTheme oldWidget) =>
      fill != oldWidget.fill ||
      border != oldWidget.border ||
      blur != oldWidget.blur ||
      radius != oldWidget.radius;
}
