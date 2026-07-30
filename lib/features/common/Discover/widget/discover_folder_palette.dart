import 'package:flutter/material.dart';

/// Colour of ONE folder in the Discover landing grid — see
/// `docs/discover_color_full.jpeg`.
///
/// The grid used to be a run of identical frosted-white plates, which made a
/// column of fourteen folders read as one undifferentiated wall. Each folder now
/// carries its own hue, so a folder is recognisable by colour before its label
/// is read and the eye has something to travel down.
///
/// Everything is derived from a single [base] hue rather than hand-listed per
/// folder: the tile wash, the border, the lift shadow and the pastel tints
/// behind each icon all come out of it. That keeps a folder internally
/// harmonious for free, and means adding a section to the grid is one colour in
/// [_kFolderBaseColors] rather than a block of six.
@immutable
class DiscoverFolderTheme {
  const DiscoverFolderTheme(this.base);

  /// The folder's hue at full strength. Never painted directly — every surface
  /// below is a softened derivation of it.
  final Color base;

  /// Wash over the blurred profile photo behind the page. Translucent rather
  /// than solid, so the grid keeps the glass character of the redesign and the
  /// photo still reads through it.
  ///
  /// Held high enough that the hue survives the photo underneath. The wash
  /// started far lighter and the folders came out muddy and near-identical:
  /// a mid-tone colour laid at ~30% over a mid-tone photo lands back at the
  /// photo, so Grocery's green and Book Home Services' olive were the same
  /// grey-green rectangle. The whole point is that a folder is identifiable by
  /// colour, and the colour cannot be at the mercy of whose profile photo is
  /// behind it.
  List<Color> get tileGradient => [
        base.withValues(alpha: 0.80),
        base.withValues(alpha: 0.55),
      ];

  /// Light rim that separates the tile from whatever it sits on. Kept white
  /// rather than tinted — a coloured rim on a coloured wash loses the edge over
  /// a busy photo.
  Color get border => Colors.white.withValues(alpha: 0.42);

  /// Lift shadow, tinted with the folder's own hue so the colour reads as
  /// belonging to the tile rather than being painted on top of a grey card.
  List<BoxShadow> get shadow => [
        BoxShadow(
          color: base.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        const BoxShadow(
          color: Color(0x14101828),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ];

  /// Pastel plate behind the icon in slot [slot].
  ///
  /// The slots are rotated around the base hue instead of all sharing it: in the
  /// reference the four plates inside a folder are visibly *different* pastels
  /// that still belong together, which is what stops a folder looking like one
  /// flat colour block. Lightness and saturation are pinned low/high enough that
  /// the illustrated icons — which carry their own strong colours — stay legible
  /// on every plate.
  Color plateTint(int slot) {
    // Wide enough that the four plates read as four different pastels — in the
    // reference a single folder holds a blue, a teal, a cream and a green — but
    // still inside one arc of the wheel, so they stay a family rather than
    // becoming confetti. A narrow spread (±20°) collapses the whole folder into
    // one flat colour block, which is the look this replaced.
    const hueShifts = <double>[-52, 30, -14, 66];
    const lightness = <double>[0.89, 0.87, 0.90, 0.86];
    final i = slot % hueShifts.length;
    final hsl = HSLColor.fromColor(base);
    // Dart's `%` returns a non-negative result for a positive divisor, so a
    // negative shift wraps correctly without a guard.
    final hue = (hsl.hue + hueShifts[i]) % 360;
    return HSLColor.fromAHSL(0.92, hue, 0.42, lightness[i]).toColor();
  }
}

/// Folder hues in landing-grid order, matching the reference top to bottom:
/// Grocery, Restaurant & Food, Home Made Food, Healthcare, Book Home Services,
/// Book Your Transport, Book Your Stay, Professionals, Rent & Properties, Find
/// Services, Financial Sectors, Automotive, Education, Jobs.
///
/// The list runs longer than the reference's fourteen so the tabs that filter
/// the grid — and any section added later — still get a hue of their own before
/// the list wraps. Neighbouring entries are kept far apart on the colour wheel:
/// folders sit two per row, so it is the *adjacent* pairs that must not read as
/// the same colour.
const List<Color> _kFolderBaseColors = [
  Color(0xFF6FA05A), // sage green    — Grocery
  Color(0xFFD98055), // terracotta    — Restaurant & Food
  Color(0xFFC79233), // golden brown  — Home Made Food
  Color(0xFFD4737F), // rose          — Healthcare Services
  Color(0xFF7FA33F), // olive         — Book Home Services
  Color(0xFF9E4A38), // deep maroon   — Book Your Transport
  Color(0xFF5FA36F), // green         — Book Your Stay
  Color(0xFF9179B8), // mauve         — Professionals Consult
  Color(0xFFD3903F), // amber         — Rent & Properties
  Color(0xFFD9698C), // pink          — Find Services
  Color(0xFF6C86C9), // periwinkle    — Financial Sectors
  Color(0xFF5C7C8A), // slate         — Automotive & Services
  Color(0xFFD98A50), // peach         — Education & Training
  Color(0xFFA96C9E), // dusty violet  — Jobs
  Color(0xFF4FA79B), // teal
  Color(0xFFB4894F), // tan
  Color(0xFF7E9B4E), // moss
  Color(0xFFC26A6A), // clay
];

/// Theme for the folder at [index] in the landing grid, wrapping round for a
/// grid longer than the palette.
DiscoverFolderTheme discoverFolderThemeFor(int index) => DiscoverFolderTheme(
    _kFolderBaseColors[index.abs() % _kFolderBaseColors.length]);
