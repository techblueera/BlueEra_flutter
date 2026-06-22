import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:flutter/material.dart';

/// Off-screen referral *invite poster* captured to a PNG and shared as
/// an image (paired with the download/referral text body). This is the
/// "industry-level" share surface: the referral code is the hero, set
/// large and bold on a tear-off coupon, on the BlueEra blue gradient.
///
/// OS share sheets can't style text, so anything that needs typography
/// or colour — like a bold, branded code — has to live in an image.
/// That's what this widget is for. Build it off-screen via
/// [ReferralShareCard.buildAndShare]; never place it in a visible tree.
class ReferralShareCard extends StatelessWidget {
  /// Must be attached to the root [RepaintBoundary] so [ShareService]
  /// can snapshot exactly this card.
  final GlobalKey cardKey;
  final String code;

  /// Fixed logical width; at the capture pixelRatio (3.0) this exports
  /// a ~1020px-wide PNG — sharp on any receiving device.
  static const double _width = 340;

  // Brand palette — kept local so the poster stays self-contained and
  // its look can be tuned without touching app-wide tokens.
  static const Color _navy = Color(0xFF003D8F);
  static const Color _blue = Color(0xFF0086FF);
  static const Color _cyan = Color(0xFF00B4FF);
  static const Color _ink = Color(0xFF090707);
  static const Color _inkSoft = Color(0xFF505050);
  static const Color _gold = Color(0xFFF5A623);

  const ReferralShareCard({
    super.key,
    required this.cardKey,
    required this.code,
  });

  /// Renders the card off-screen in an [OverlayEntry], waits for it to
  /// paint, then hands it to [ShareService.shareReferralImageCard].
  /// Mirrors the visiting-card capture flow. [code] is passed through
  /// as the override so the text body carries the same code shown on
  /// the poster, even before the profile controller has loaded.
  static Future<void> buildAndShare(
    BuildContext context, {
    required String code,
  }) async {
    if (code.isEmpty) return;

    // Logo is the only raster asset on the card — precache it so the
    // capture doesn't race the decode and snapshot a blank slot.
    await precacheImage(const AssetImage(AppImageAssets.app_logo), context);

    final cardKey = GlobalKey();
    final overlay = OverlayEntry(
      // Translate far off-screen: present in the tree (so the
      // RepaintBoundary can capture) but invisible to the user.
      builder: (_) => Transform.translate(
        offset: const Offset(0, -10000),
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topLeft,
            child: ReferralShareCard(cardKey: cardKey, code: code),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    try {
      // One frame to paint, plus a small cushion for slow devices.
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));
      await ShareService.instance.shareReferralImageCard(
        cardKey: cardKey,
        overrideReferralCode: code,
      );
    } finally {
      overlay.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: SizedBox(
        width: _width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_navy, _blue, _cyan],
              ),
            ),
            child: Stack(
              children: [
                // Ambient brand glow — two faint circles add depth to
                // the flat gradient without competing with the code.
                Positioned(
                  top: -48,
                  right: -36,
                  child: _glow(120),
                ),
                Positioned(
                  bottom: -56,
                  left: -44,
                  child: _glow(140),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      const Text(
                        "You're invited to BlueEra",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "India's own super-app for social, jobs, "
                        "shopping & services.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _coupon(),
                      const SizedBox(height: 16),
                      _storeRow(),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Download BlueEra & enter this code at sign-up',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
        ),
      );

  /// Top lockup: white logo badge on the left, "REFER & EARN" eyebrow
  /// pill on the right.
  Widget _header() => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Image.asset(
              AppImageAssets.app_logo,
              height: 20,
              // If the logo asset can't load, fall back to the wordmark
              // so the badge is never an empty white box.
              errorBuilder: (_, __, ___) => const Text(
                'BlueEra',
                style: TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'REFER & EARN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      );

  /// The signature element: a tear-off coupon with real notches cut
  /// from its sides ([_TicketClipper]). Top half holds the code as the
  /// hero; bottom half carries the reward CTA.
  Widget _coupon() => ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            children: [
              const Text(
                'YOUR REFERRAL CODE',
                style: TextStyle(
                  color: _inkSoft,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              // The hero. FittedBox guards against unusually long codes
              // overflowing the ticket width.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  code.toUpperCase(),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      size: 15, color: _gold),
                  const SizedBox(width: 6),
                  Text(
                    'Apply at sign-up & get rewarded',
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _storeRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _storeChip(Icons.play_arrow_rounded, 'Google Play'),
          const SizedBox(width: 10),
          _storeChip(Icons.apple, 'App Store'),
        ],
      );

  Widget _storeChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

/// Clips a rounded rectangle with a semicircular notch cut from the
/// vertical middle of each side — the classic tear-off ticket profile.
/// The card's blue gradient shows through the notches.
class _TicketClipper extends CustomClipper<Path> {
  final double radius = 18;
  final double notch = 11;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: Radius.circular(radius))
      ..lineTo(w, midY - notch)
      // right-edge notch (bulges inward)
      ..arcToPoint(Offset(w, midY + notch),
          radius: Radius.circular(notch), clockwise: false)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: Radius.circular(radius))
      ..lineTo(radius, h)
      ..arcToPoint(Offset(0, h - radius), radius: Radius.circular(radius))
      ..lineTo(0, midY + notch)
      // left-edge notch (bulges inward)
      ..arcToPoint(Offset(0, midY - notch),
          radius: Radius.circular(notch), clockwise: false)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
