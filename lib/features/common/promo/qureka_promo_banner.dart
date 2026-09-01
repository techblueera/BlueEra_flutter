import 'dart:math';

import 'package:BlueEra/core/services/ads/native_ad_list_inserter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the Qureka promo banners point.
///
/// One constant for every placement — Discover, the Social feed and the store
/// listings all read this, so the destination can never differ between them.
///
/// Empty disables the promo entirely: [QurekaPromoBanner] renders nothing when
/// this is blank, so the banners can be pulled from all three screens by
/// clearing this one line, with no other edit and no dead artwork left behind.
///
/// If a partner ever supplies a tracked link (a `?pub=` / `?utm_` variant),
/// replace the whole value here rather than appending at the call sites — the
/// point of a single constant is that attribution can't drift between
/// placements.
const String kQurekaPromoUrl = 'https://qureka.com/';

/// The bundled Qureka Lite creatives, in `assets/qureka/`.
///
/// All six are wide banners at roughly 16:9 (900x506 or 800x480), so they share
/// one box — see [QurekaPromoBanner._aspect].
class QurekaCreatives {
  QurekaCreatives._();

  /// "Play GK Quiz & Earn upto 50,000 coins".
  static const String gkQuiz = 'assets/qureka/gk_quiz.jpg';

  /// IPL cricket quiz.
  static const String iplQuiz = 'assets/qureka/ipl_quiz.jpg';

  /// History quiz.
  static const String historyQuiz = 'assets/qureka/history_quiz.jpg';

  /// Tech-skills quiz.
  static const String techSkillsQuiz = 'assets/qureka/tech_skills_quiz.jpg';

  /// "SSC EXAM Quiz for 50,000 Coins is Live".
  static const String sscExamQuiz = 'assets/qureka/ssc_exam_quiz.png';

  /// "SSC, BANK PO क्लियर करना है?" — the Hindi exam-prep creative.
  static const String sscBankPoQuiz = 'assets/qureka/ssc_bank_po_quiz.png';

  static const List<String> all = [
    gkQuiz,
    iplQuiz,
    historyQuiz,
    techSkillsQuiz,
    sscExamQuiz,
    sscBankPoQuiz,
  ];

  // ── Slim 320x50 strips ────────────────────────────────────────────────
  //
  // A different SHAPE, not just different art: at 6.4:1 these are a banner
  // strip rather than a card. They exist for surfaces where a full 16:9 card
  // would be too much — the "Me" tabs, where the merchant came to work and the
  // promo has to stay out of the way.

  /// "Play Tech Quiz & Earn upto 15,000 coins".
  static const String techQuizStrip = 'assets/qureka/tech_quiz_strip.jpg';

  /// "Play Cricket Quiz & Earn upto 50,000 coins daily".
  static const String cricketQuizStrip =
      'assets/qureka/cricket_quiz_strip.jpg';

  static const List<String> strips = [techQuizStrip, cricketQuizStrip];
}

/// While true, the surfaces that opted in by using [PromoAdSlot] fill their ad
/// rows with Qureka promo cards instead of Google/Meta native ads.
///
/// This is the "for now" switch. Flip it to false and every one of those slots
/// goes straight back to serving real native ads with no other edit — the call
/// sites keep the exact same arguments, because [PromoAdSlot] takes the same
/// ones [NativeAdSlot] does and simply forwards them.
///
/// Screens NOT using [PromoAdSlot] (jobs, education, healthcare, finance,
/// rentals, stays, professions, the channel feed) are untouched by this and
/// keep serving native ads regardless.
const bool kQurekaReplacesNativeAds = true;

/// An ad row that renders EITHER a Qureka promo card or a real native ad,
/// decided by [kQurekaReplacesNativeAds].
///
/// A drop-in for [NativeAdSlot]: same constructor arguments, so switching a
/// screen over is a one-word change at the call site and switching back is one
/// bool. The native-ad-only arguments ([factoryId], [height], [adOrdinal] …)
/// are still accepted while the promo is showing — the promo ignores them, but
/// keeping them means nothing has to be re-derived when ads come back.
///
/// [adOrdinal] doubles as the promo's creative index, so a list with several ad
/// rows shows a DIFFERENT quiz card in each rather than the same one repeated
/// down the page.
class PromoAdSlot extends StatelessWidget {
  const PromoAdSlot({
    super.key,
    required this.adOrdinal,
    this.keyPrefix = 'native_ad',
    this.height = 300,
    this.factoryId = 'groceryAdFactory',
    this.borderRadius = 12,
    this.bottomGap,
    this.margin,
    this.border,
    this.boxShadow,
    this.backgroundColor,
  });

  final int adOrdinal;
  final String keyPrefix;
  final double height;
  final String factoryId;
  final double borderRadius;
  final double? bottomGap;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!kQurekaReplacesNativeAds) {
      return NativeAdSlot(
        adOrdinal: adOrdinal,
        keyPrefix: keyPrefix,
        height: height,
        factoryId: factoryId,
        borderRadius: borderRadius,
        bottomGap: bottomGap,
        margin: margin,
        border: border,
        boxShadow: boxShadow,
        backgroundColor: backgroundColor,
      );
    }
    return QurekaPromoBanner(
      // Cycle by ordinal rather than at random: within one list the cards then
      // differ from each other, and they stay put across rebuilds instead of
      // reshuffling every time the list repaints.
      creative:
          QurekaCreatives.all[adOrdinal.abs() % QurekaCreatives.all.length],
      margin: margin ??
          EdgeInsets.fromLTRB(0, 0, 0, bottomGap ?? 12),
      borderRadius: borderRadius,
    );
  }
}

/// The slim 320x50 strip the "Me" tabs use, as a standalone widget.
///
/// [QurekaPromoBanner] with the strip aspect and the strip artwork — same tap
/// behaviour, same "hidden when unconfigured" rule.
const Widget kQurekaStrip = QurekaPromoBanner(
  strip: true,
  margin: EdgeInsets.fromLTRB(0, 16, 20, 4),
);

/// [content] with the promo STRIP appended under it, for use **inside** a
/// scroll view.
///
/// This is how the "Me" screens carry the promo: each wraps its first tab in a
/// `_tabScroll(...)` helper (a `SingleChildScrollView`), and passing the tab
/// through here puts the strip in that scroll's CONTENT. It therefore scrolls
/// with the tab and comes to rest after the last row, rather than being pinned
/// as a separate band above or below the list — which is what it looked like
/// while the wrapping was done from `HomeTabScaffold`, outside the scrollable.
///
/// Right padding only: those tab scrolls are laid out with a left inset and no
/// right one, so the strip supplies its own to sit square with the content.
Widget withQurekaPromoBelow(Widget content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [content, kQurekaStrip],
  );
}

/// [withQurekaPromoBelow] for the two "Me" screens whose `_tabScroll` takes a
/// `List<Widget>` (content creator, professionals) rather than a single child.
List<Widget> withQurekaPromoBelowAll(List<Widget> content) {
  return [...content, kQurekaStrip];
}

/// A tappable Qureka Lite promo banner that opens [kQurekaPromoUrl] **inside the
/// app**.
///
/// `LaunchMode.inAppWebView` rather than `externalApplication`: this is a promo,
/// and bouncing the user out to Chrome loses them — the app goes to the
/// background and coming back is their problem. In-app keeps the back button
/// pointing at wherever they were. It is the same mode the channel links use.
///
/// **Renders nothing when [kQurekaPromoUrl] is empty**, so every placement is
/// inert until the link is configured. It also collapses when its artwork is
/// missing, so a stale asset bundle leaves a clean page rather than a grey
/// broken-image box.
class QurekaPromoBanner extends StatelessWidget {
  const QurekaPromoBanner({
    super.key,
    this.creative,
    this.strip = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = 16,
  });

  /// Which artwork to show. Null picks one per mount from the matching set —
  /// placements that appear on several screens then don't all show the
  /// identical banner, without any of them having to coordinate.
  final String? creative;

  /// Draw the slim 320x50 BANNER STRIP instead of the 16:9 card.
  ///
  /// Not a styling flag — it selects a different set of artwork
  /// ([QurekaCreatives.strips]) with a different shape. A card cropped to strip
  /// height would lose most of its message; the strips are drawn for it.
  final bool strip;

  final EdgeInsetsGeometry margin;
  final double borderRadius;

  /// The cards are 900x506 and 800x480; 16:9 sits between them, so `cover`
  /// trims a hair off the taller ones rather than letterboxing any of them.
  static const double _cardAspect = 16 / 9;

  /// The strips are exactly 320x50.
  static const double _stripAspect = 320 / 50;

  static final Random _rng = Random();

  Future<void> _open() async {
    final raw = kQurekaPromoUrl.trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (_) {
      // A device with no browser at all — nothing useful to say, and a promo is
      // not worth a snackbar over.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not configured → not shown. See [kQurekaPromoUrl].
    if (kQurekaPromoUrl.trim().isEmpty) return const SizedBox.shrink();

    final set = strip ? QurekaCreatives.strips : QurekaCreatives.all;
    final art = creative ?? set[_rng.nextInt(set.length)];

    return Padding(
      padding: margin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: ClipRRect(
          // A 50pt-tall strip with a 16pt radius reads as a pill; it takes its
          // own, smaller corner.
          borderRadius: BorderRadius.circular(strip ? 8 : borderRadius),
          child: AspectRatio(
            aspectRatio: strip ? _stripAspect : _cardAspect,
            child: Image.asset(
              art,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
