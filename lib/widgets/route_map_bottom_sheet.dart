import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photo_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// The sheet that opens when a location is tapped: which place, how far, the
/// address, its photos, and the handoff to Google Maps.
///
/// ## Why there is no map in here any more
///
/// This used to embed a live [GoogleMap] with a polyline fetched from the
/// Directions API. It was the wrong trade three times over:
///
///  * **It cost money on every open.** One Directions call plus a Maps SDK
///    render per tap, on a sheet that is tapped from every store card in the
///    app. See docs/GOOGLE_MAPS_COST_GUIDE.md.
///  * **It was a picture, not a route.** 200px of non-interactive preview can't
///    reroute, can't say "12 min", and can't be followed while walking. The
///    user's next move after looking at it was always to open Google Maps.
///  * **It delayed the sheet.** The route arrived after the sheet did, so the
///    first thing the user saw was a "Loading route…" chip over an empty map.
///
/// So the sheet answers what it is actually good at — identity, distance,
/// address, photos — and [openGoogleMapsDirections] draws the real line, in the
/// app that owns navigation, with live traffic and an ETA.
///
/// ## How it's laid out, and why
///
/// The sheet describes a LEG: you are here, the place is there, and this much
/// separates them. So it's drawn as one — a hollow origin dot, a dashed
/// connector carrying the distance, and a filled pin holding the address. That
/// replaced a flat stack in which the distance was a grey caption under the
/// name and the address was a line of text with a mystery icon at the end of
/// it; the two facts sat next to each other without either saying it was
/// measuring the gap between two points.
///
/// The rail is the only place the brand blue appears (plus the action that acts
/// on it). Everything else is ink, grey, and space — so the eye lands on the
/// journey, which is the whole reason the sheet was opened.
///
/// The connector draws downward once as the sheet settles. One motion, on the
/// element that is literally about traversal, and it's skipped outright when
/// the platform asks for reduced motion.
class RouteMapBottomSheet extends StatefulWidget {
  final String destinationName;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double userLat;
  final double userLng;
  final List<String>? livePhotos;
  final VoidCallback? visitCallback;

  /// Label for the primary action, for callers that can name the destination
  /// better than this widget can.
  ///
  /// The sheet is opened over shops, restaurants, pharmacies and rental
  /// properties alike, so it can't hardcode "View store" without being wrong
  /// somewhere. Defaults to the generic [AppStrings.view].
  final String? visitLabel;

  const RouteMapBottomSheet({
    super.key,
    required this.destinationName,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.userLat,
    required this.userLng,
    this.visitCallback,
    this.visitLabel,
    this.livePhotos,
  });

  /// Convenience method to show the bottom sheet from anywhere.
  static void show({
    required BuildContext context,
    required String destinationName,
    String destinationAddress = '',
    required double destinationLat,
    required double destinationLng,
    VoidCallback? visitCallback,
    String? visitLabel,
    double? userLat,
    double? userLng,
    List<String>? livePhotos,
  }) {
    final uLat = userLat ?? LocationService.lat;
    final uLng = userLng ?? LocationService.lng;

    if (destinationLat == 0.0 && destinationLng == 0.0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // A long address plus a photo strip can outgrow a short screen. Capped
      // and scrollable so the actions stay reachable instead of the column
      // overflowing off the bottom.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (_) => RouteMapBottomSheet(
        destinationName: destinationName,
        destinationAddress: destinationAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        userLat: uLat,
        userLng: uLng,
        livePhotos: livePhotos,
        visitCallback: visitCallback,
        visitLabel: visitLabel,
      ),
    );
  }

  @override
  State<RouteMapBottomSheet> createState() => _RouteMapBottomSheetState();
}

class _RouteMapBottomSheetState extends State<RouteMapBottomSheet>
    with SingleTickerProviderStateMixin {
  // ─── Tokens ─────────────────────────────────────────────────────────────
  //
  // Deliberately few: one accent, two inks, one hairline. The sheet opens over
  // fourteen different screens, so it borrows the app's blue rather than
  // inventing a palette that would read as a different product.

  /// The route colour — origin dot, dashes, pin, distance, directions. Nothing
  /// else on the sheet is allowed to use it.
  static const Color _accent = AppColors.primaryColor;
  static const Color _ink = AppColors.mainTextColor;
  static const Color _muted = AppColors.secondaryTextColor;
  static const Color _hairline = Color(0xFFE7ECF2);
  static const Color _sheet = AppColors.white;

  /// Node sizes for the route rail. The origin is small and hollow, the
  /// destination larger and filled: the weight difference is what says which
  /// end of the leg you are going to.
  static const double _originNode = 18;
  static const double _destNode = 28;
  static const double _railWidth = _destNode;
  static const double _connectorHeight = 34;

  late final AnimationController _controller;
  late final Animation<double> _draw;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _draw = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    // Started after the first frame so the line draws while the sheet is
    // settling rather than racing it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the rail is a diagram, not the animation. Jump it to its
    // finished state and show the same thing without the travel.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _validPhotos =>
      widget.livePhotos?.where((p) => p.trim().isNotEmpty).toList() ?? [];

  /// Whether the device actually has a fix. Without one there is no origin, so
  /// there is no leg to draw and no distance worth printing — `0,0` would put
  /// the user in the Gulf of Guinea and claim a confident 6,231 km.
  bool get _hasOrigin => widget.userLat != 0.0 || widget.userLng != 0.0;

  /// Hands the leg to Google Maps on its DIRECTIONS view — the drawn route with
  /// distance and ETA, not turn-by-turn guidance, which would be presumptuous
  /// for someone who has only tapped a shop's address.
  ///
  /// The origin is passed only when the device actually has a fix; omitting it
  /// lets Google Maps use its own current location, which is the better answer
  /// anyway when ours is stale.
  Future<void> _openDirections() async {
    try {
      await openGoogleMapsDirections(
        destinationLat: widget.destinationLat,
        destinationLng: widget.destinationLng,
        originLat: _hasOrigin ? widget.userLat : null,
        originLng: _hasOrigin ? widget.userLng : null,
      );
    } catch (_) {
      commonSnackBar(message: "Google Maps didn't open. Check that it's installed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = _validPhotos.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _routeRail(),
                    const SizedBox(height: 22),
                    _actions(),
                    if (hasPhotos) ...[
                      const SizedBox(height: 24),
                      _photosLabel(),
                      const SizedBox(height: 10),
                      _photos(context),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chrome ─────────────────────────────────────────────────────────────

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: _hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  /// Name and dismiss. The name is the largest thing on the sheet and the only
  /// thing at that weight — it identifies what the whole panel is about, and
  /// tapping it opens the place, same as the primary action.
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.visitCallback == null ? null : _visit,
            child: CustomText(
              widget.destinationName,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.2,
              letterSpacing: -0.2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Close',
          child: InkResponse(
            onTap: () => Navigator.of(context).maybePop(),
            radius: 22,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 17, color: _muted),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Signature: the route rail ──────────────────────────────────────────

  /// The leg, drawn: `◎ your location ┆ 4.5 km ┆ ◉ address`.
  ///
  /// Three rows sharing one [_railWidth] gutter, so the dot, the dashes and the
  /// pin stack into a single vertical line. Fixed node and connector heights —
  /// no [IntrinsicHeight] — because the gutter must not resize when the address
  /// wraps to a second line.
  ///
  /// With no location fix the origin half is dropped entirely rather than
  /// faked: the sheet then says where the place is, and stops claiming to know
  /// how far away it is from you.
  Widget _routeRail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasOrigin) ...[
          _railRow(
            gutter: _originDot(),
            gutterHeight: _originNode,
            child: CustomText(
              'Your location',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 0.1,
            ),
          ),
          _connector(),
        ],
        _railRow(
          gutter: _destinationPin(),
          gutterHeight: _destNode,
          // The address sits a hair below the pin's top edge so its first line
          // reads as level with the glyph.
          childPadding: const EdgeInsets.only(top: 4),
          child: CustomText(
            widget.destinationAddress.isNotEmpty
                ? widget.destinationAddress
                : AppStrings.na,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _ink,
            height: 1.35,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// One rung of the rail: a fixed-width gutter glyph and its content.
  Widget _railRow({
    required Widget gutter,
    required double gutterHeight,
    required Widget child,
    EdgeInsets childPadding = EdgeInsets.zero,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _railWidth,
          height: gutterHeight,
          child: Center(child: gutter),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: childPadding,
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  /// Hollow ring — the standard "you are here" mark, and light enough that the
  /// filled pin below reads as the end of the leg.
  Widget _originDot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _sheet,
        border: Border.all(color: _accent, width: 3),
      ),
    );
  }

  /// Filled pin — the destination, and the heaviest mark in the gutter.
  Widget _destinationPin() {
    return Container(
      width: _destNode,
      height: _destNode,
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: AppColors.white,
          height: 15,
          width: 13,
        ),
      ),
    );
  }

  /// The dashed span, with the distance riding on it.
  ///
  /// The line draws downward on open and the figure fades in behind it, so the
  /// distance arrives as the consequence of the travel rather than as another
  /// label that was always there.
  Widget _connector() {
    final km = calculateDistanceKm(
      widget.userLat,
      widget.userLng,
      widget.destinationLat,
      widget.destinationLng,
    );
    return SizedBox(
      height: _connectorHeight,
      child: AnimatedBuilder(
        animation: _draw,
        builder: (context, _) {
          final t = _draw.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                height: _connectorHeight,
                child: CustomPaint(
                  painter: _DashedConnectorPainter(
                    progress: t,
                    color: _accent.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: ((t - 0.35) / 0.65).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(
                      '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  /// Two peers, not a conclusion.
  ///
  /// Directions used to be a 46px slab of brand blue under the address, which
  /// said the sheet was for leaving to Google Maps; then it was an unlabelled
  /// icon on the end of the address line, which said nothing at all. It's a
  /// real button again — but tinted, and on the left — while the filled one
  /// keeps you in the app. When there's nowhere to visit, directions IS the
  /// conclusion and takes the full width.
  Widget _actions() {
    final directions = _button(
      label: 'Directions',
      icon: Icons.directions_rounded,
      filled: false,
      onTap: _openDirections,
    );

    if (widget.visitCallback == null) return directions;

    return Row(
      children: [
        Expanded(child: directions),
        const SizedBox(width: 10),
        Expanded(
          child: _button(
            label: widget.visitLabel ?? AppStrings.view,
            icon: Icons.arrow_forward_rounded,
            filled: true,
            onTap: _visit,
          ),
        ),
      ],
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final Color foreground = filled ? AppColors.white : _accent;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? _accent : _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: filled ? _accent : _accent.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                CustomText(
                  label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  letterSpacing: 0.1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _visit() {
    Navigator.of(context).maybePop();
    widget.visitCallback?.call();
  }

  // ─── Photos ─────────────────────────────────────────────────────────────

  /// A tracked, uppercase rule rather than a heading with a shop glyph: it
  /// labels the strip below it without competing with the name at the top for
  /// "title of this sheet".
  Widget _photosLabel() {
    return Row(
      children: [
        CustomText(
          'STORE PHOTOS',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _muted,
          letterSpacing: 1.1,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _hairline,
            borderRadius: BorderRadius.circular(6),
          ),
          child: CustomText(
            '${_validPhotos.length}',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _photos(BuildContext context) {
    return StoreLivePhotoWidget(
      livePhotos: _validPhotos,
      natureOfBusiness: widget.destinationName,
      height: 160,
      onViewFullScreen: ({
        required int index,
        required List<String> storeImage,
        required String natureOfBusiness,
      }) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewScreen(
              appBarTitle: widget.destinationName,
              subTitle: widget.destinationName,
              imageUrls: storeImage,
              initialIndex: index,
            ),
          ),
        );
      },
    );
  }
}

/// The dashed span between the two rail nodes, drawn top-down to [progress].
///
/// Dashes rather than a solid rule because the gap between you and the shop is
/// not a drawn route — the sheet knows the straight-line distance, not the path
/// — and a solid line would imply one.
class _DashedConnectorPainter extends CustomPainter {
  const _DashedConnectorPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const double _dash = 3;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;
    final drawn = size.height * progress.clamp(0.0, 1.0);

    double y = 0;
    while (y < drawn) {
      final end = (y + _dash).clamp(0.0, drawn);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(_DashedConnectorPainter old) =>
      old.progress != progress || old.color != color;
}
