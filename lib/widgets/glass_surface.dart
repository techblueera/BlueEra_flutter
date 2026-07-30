import 'package:flutter/material.dart';

/// Marks a subtree that sits on the app-wide background banner
/// (`AppHomeBackground`) and should therefore paint its panels as **glass** —
/// translucent white over that banner — instead of the solid white cards used
/// everywhere else in the app.
///
/// The switch lives in a scope rather than in the widgets themselves because
/// the surfaces involved are shared. [FeedCardWidget] is the single card behind
/// every post in the app: the Connect feed, the community feed, post detail,
/// the repost composer, the profile overview. Turning it glass outright would
/// turn it glass on the screens that still have a plain white page behind them,
/// where a translucent card reads as a rendering bug. Wrapping only the screen
/// that wants the look keeps every other caller exactly as it was.
///
/// This is the same mechanism [DiscoverFolderScope] uses for the Discover
/// landing grid, for the same reason.
class GlassScope extends InheritedWidget {
  const GlassScope({super.key, required this.enabled, required super.child});

  final bool enabled;

  /// Whether the caller should paint itself as glass.
  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassScope>()?.enabled ?? false;

  @override
  bool updateShouldNotify(GlassScope oldWidget) => enabled != oldWidget.enabled;
}

/// ## Why this is plain alpha and NOT a [BackdropFilter]
///
/// A BackdropFilter forces a `saveLayer` and re-samples everything painted
/// beneath it every frame. In a scrolling list that means one sampled layer
/// *per post card*, which is both a frame-time cliff and the exact setup that
/// smeared text on Discover (see the note on `_DiscoverHeaderDelegate` — a
/// device-dependent Android GPU/driver bug that will not reproduce on most dev
/// hardware).
///
/// The glass read here comes from alpha over the app-wide background banner
/// instead: nothing is sampled per frame, so scrolling stays cheap and the
/// artifact cannot occur. The fixed chrome at the top of the screen (the search
/// header) keeps its real BackdropFilter — it is one layer that does not
/// multiply with content.

/// Card-weight glass — feed and community post cards.
///
/// Noticeably more opaque than [kGlassPanelGradient]: a post card carries dense
/// dark body text, and the banner behind it is a user-chosen image of unknown
/// brightness. This is the level where the text still holds up over a dark
/// banner while the card is clearly translucent rather than white.
const List<Color> kGlassCardGradient = [Color(0xC7FFFFFF), Color(0x9EFFFFFF)];

/// Panel-weight glass — chrome that frames content rather than carrying it
/// (the header pane, the tab strip, the symbol rail). Lighter than a card
/// because there is little text on it and it should let the banner read
/// through.
const List<Color> kGlassPanelGradient = [Color(0x8CFFFFFF), Color(0x52FFFFFF)];

/// Inset glass — small blocks *inside* an already-glass card. Kept low so two
/// stacked translucencies don't add up to an opaque white patch.
const List<Color> kGlassInsetGradient = [Color(0x6EFFFFFF), Color(0x47FFFFFF)];

/// Hairline rim. Glass has no fill of its own to define its edge, so the rim is
/// what keeps a card's shape crisp over a busy banner.
const Color kGlassBorderColor = Color(0x99FFFFFF);

/// Soft lift, so a glass panel still reads as floating above the banner.
const List<BoxShadow> kGlassShadow = [
  BoxShadow(color: Color(0x14101828), blurRadius: 10, offset: Offset(0, 3)),
];

// ─── The chat-list sheet ─────────────────────────────────────────────────────
//
// The chat list (docs/chat_new.jpeg) is one frosted sheet with the rows sitting
// ON it, keeping their normal dark text — NOT rows floating on the bare banner
// in white text. That distinction is the whole design: the sheet supplies the
// contrast, so legibility stops depending on which wallpaper the user picked,
// and the banner still reads through as colour and gradient rather than being
// covered by an opaque white page.

/// Wash for the chat-list sheet.
///
/// Heavier than [kGlassPanelGradient] because this one has dark body text on it
/// rather than a few glyphs, and the banner behind it can be any brightness.
///
/// These values are measured, not guessed. The banner is user-chosen, so the
/// worst case is a DARK one, where a translucent sheet lands dark too and the
/// text on it loses its background. At a lighter wash the message preview came
/// out at 1.3:1 against this sheet — invisible. Here the preview holds ~4.2:1
/// and a name ~9.8:1 even over a black banner, while a mid-tone banner still
/// tints the sheet and reads through it as the reference shows.
const List<Color> kGlassSheetGradient = [Color(0xC2FFFFFF), Color(0xA5FFFFFF)];

/// Secondary text on the sheet — message previews, timestamps.
///
/// Darker than the [AppColors.grey9A] the row uses on a solid white page. That
/// grey was picked against pure white; on a translucent sheet over a dark
/// banner it drops to ~1.3:1. This is also closer to the reference, where the
/// previews read as a firm grey rather than the pale one on white.
const Color kGlassSheetSecondaryText = Color(0xFF404A54);

/// Corner radius where the sheet meets the header above it.
const double kGlassSheetRadius = 24;

/// Side inset, so a ribbon of the banner stays visible past the sheet's edges
/// and it reads as a sheet laid ON the background rather than as the page.
const double kGlassSheetInset = 8;

/// Hairline rule between rows on the sheet. Dark, not white: it sits on a light
/// frosted surface, so it is a shadow line the way an ordinary divider is.
const Color kGlassDivider = Color(0x1F101828);

/// The sheet's surface as a [BoxDecoration], for callers that supply their own
/// geometry — e.g. the Me-side list card, which is a rounded card with margins
/// rather than a full-height sheet, but is the same surface.
BoxDecoration glassSheetDecoration({BorderRadiusGeometry? borderRadius}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: kGlassSheetGradient,
    ),
    borderRadius: borderRadius,
    border: Border.all(color: kGlassBorderColor),
  );
}

/// The frosted sheet itself — rounded at the top, inset at the sides, running
/// off the bottom of the screen.
///
/// It is deliberately NOT wrapped around a whole tab body. In the reference the
/// sheet's top edge starts *below* the filter chips (All / Pinned / Reminder /
/// …), which stay up on the header band — so it goes around the scrolling list
/// inside each tab rather than around everything. Placing it higher would put
/// the chips inside the panel and lose that edge.
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kGlassSheetInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: kGlassSheetGradient,
          ),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(kGlassSheetRadius)),
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(kGlassSheetRadius)),
          child: child,
        ),
      ),
    );
  }
}

/// The glass recipe as a [BoxDecoration], so call sites swap one decoration for
/// another instead of repeating the gradient/border/shadow trio.
BoxDecoration glassDecoration({
  BorderRadiusGeometry? borderRadius,
  List<Color> colors = kGlassCardGradient,
  Color borderColor = kGlassBorderColor,
  List<BoxShadow> shadow = kGlassShadow,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ),
    borderRadius: shape == BoxShape.circle ? null : borderRadius,
    border: Border.all(color: borderColor, width: 1),
    boxShadow: shadow,
    shape: shape,
  );
}
