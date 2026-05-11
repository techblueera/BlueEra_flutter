import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_thirteen.dart';
import 'package:flutter/material.dart';

/// Thin compatibility shell over [ShareService]. The original
/// `shareVisitingCard` instance method is preserved as a forwarder so
/// the eight or so existing call sites (`share_button.dart`,
/// `bdm_id_card_page.dart`, `more_cards_screen.dart`,
/// `greeting_card_dialog.dart`, the product / service / food cards,
/// etc.) keep working unchanged. New code should reach for
/// [ShareService.instance.shareCard] directly — that is now the single
/// canonical entry point.
class VisitingCardHelper {
  /// Forwarder onto [ShareService.instance.shareCard]. Kept on the
  /// helper for back-compat with surfaces that already call
  /// `VisitingCardHelper().shareVisitingCard(...)`. Behavior is
  /// identical, including the re-entrancy guard — the singleton's
  /// `_isSharing` flag covers every share button in the app.
  Future<void> shareVisitingCard(
    GlobalKey cardKey, {
    bool shareProfile = true,
    String? productId,
    String? serviceId,
    String? foodServiceId,
  }) {
    return ShareService.instance.shareCard(
      cardKey,
      shareProfile: shareProfile,
      productId: productId,
      serviceId: serviceId,
      foodServiceId: foodServiceId,
    );
  }

  /// Builds a [VisitingCardThirteen] off-screen via an [OverlayEntry],
  /// waits for it to paint, captures it, and routes through
  /// [ShareService.instance.shareCard] with `shareProfile: false` —
  /// the auto-generated card already encodes the user's identity,
  /// so the share body falls back to the app-download message.
  static Future<void> buildAndShareVisitingCard(BuildContext context) async {
    final GlobalKey cardKey = GlobalKey();

    // 1. Insert the card into an OverlayEntry translated 9999pt up
    // — visually invisible to the user, but still in the widget tree
    // so the RepaintBoundary can capture it.
    final overlay = OverlayEntry(
      builder: (_) => Transform.translate(
        offset: const Offset(0, -9999),
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: VisitingCardThirteen(cardKey: cardKey),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);

    // Wait for the first frame to actually paint the overlay…
    await WidgetsBinding.instance.endOfFrame;
    // …plus one extra delay for slow devices that need another pump
    // before the RepaintBoundary's render object is wired up.
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await ShareService.instance
          .shareCard(cardKey, shareProfile: false);
    } finally {
      overlay.remove();
    }
  }
}
