import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_palette.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Marks the subtree where Discover sections render as **folders** instead of
/// full-width cards — the launcher-style landing grid (see `docs/new_discov.jpeg`).
///
/// Every Discover section is built from the same two widgets
/// (`DiscoverCategorySection` / `DiscoverGridSection`, plus the hand-rolled
/// transport card), so switching the whole page between the two looks is a
/// matter of flipping this scope rather than rewriting each of the ~15 section
/// widgets. In folder mode a section collapses to one square tile showing a
/// preview of its icons; tapping it opens the *unchanged* full section in a
/// sheet, so every existing tap route stays exactly as it was.
class DiscoverFolderScope extends InheritedWidget {
  const DiscoverFolderScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  /// Whether the calling section should render as a folder tile.
  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<DiscoverFolderScope>()
          ?.enabled ??
      false;

  @override
  bool updateShouldNotify(DiscoverFolderScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Carries the *section widget* a folder was built from, so opening the folder
/// can mount a LIVE second instance of it in the sheet instead of replaying a
/// snapshot of the card taken when the grid was built.
///
/// This matters for the sections that own state: `ShoppingCardWidget` and
/// `BookHomeServiceWidget` both toggle "Show more"/"Show less" through
/// `setState`. A captured card would freeze at whatever the grid saw, because
/// the sheet is a separate route that the page's `setState` never rebuilds.
/// Mounting the widget itself gives the sheet its own State, so the toggle
/// works inside it.
///
/// Re-using one widget instance in two places is fine — widgets are immutable
/// configuration, and each mount gets its own Element/State (there are no
/// GlobalKeys on these sections).
class DiscoverFolderHost extends InheritedWidget {
  DiscoverFolderHost({super.key, required this.section, this.index = 0})
      : super(child: section);

  final Widget section;

  /// Position of this folder in the landing grid, which is what picks its
  /// colour — see [discoverFolderThemeFor].
  ///
  /// Position rather than title: the titles are localised (`AppStrings…tr`), so
  /// keying colours off them would hand a folder a different colour in every
  /// language. The grid builds this list in a fixed order, so the index is the
  /// stable identity.
  final int index;

  /// The section widget wrapping the caller, if the landing grid put one there.
  static Widget? sectionOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DiscoverFolderHost>()
      ?.section;

  /// Grid position of the folder wrapping the caller; 0 outside the grid.
  static int indexOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiscoverFolderHost>()?.index ??
      0;

  @override
  bool updateShouldNotify(DiscoverFolderHost oldWidget) =>
      section != oldWidget.section || index != oldWidget.index;
}

/// One launcher-style folder: a translucent rounded square holding a 2x2
/// preview of the section's icons, with the section title underneath.
///
/// Up to four icons fill the four slots; a section with more than four keeps
/// three full-size slots and packs the next four into a mini 2x2 in the last
/// slot — the same "there's more inside" cue a phone home-screen folder gives.
/// Slots with no icon stay as empty plates so every folder keeps the same 2x2
/// footprint whether its data has loaded or not.
class DiscoverFolderTile extends StatelessWidget {
  const DiscoverFolderTile({
    super.key,
    required this.title,
    required this.iconPaths,
    required this.expandedBuilder,
  });

  final String title;

  /// Icons previewed inside the folder, in section order. Asset paths and
  /// network URLs are both accepted (Discover mixes bundled illustrations with
  /// backend category images).
  final List<String> iconPaths;

  /// The section exactly as it renders outside folder mode — shown in the sheet
  /// when the folder is opened.
  final WidgetBuilder expandedBuilder;

  @override
  Widget build(BuildContext context) {
    // Colour comes from the folder's slot in the landing grid, published by the
    // [DiscoverFolderHost] the grid wraps every section in. Nothing is passed in
    // by the ~15 section widgets that build these tiles.
    final theme = discoverFolderThemeFor(DiscoverFolderHost.indexOf(context));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => DiscoverFolderSheet.show(context, title, expandedBuilder),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // Coloured wash over the app background behind the page: still
                // translucent, so the folder keeps picking up whatever it sits
                // on, but tinted with this folder's own hue.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.tileGradient,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: theme.border),
                boxShadow: theme.shadow,
              ),
              child: _preview(theme),
            ),
          ),
          SizedBox(height: SizeConfig.size8),
          // The label sits on the app background, not on the tile, so it has no
          // plate of its own to borrow contrast from — and the page no longer
          // dims that background. It therefore draws itself OUTLINED (see
          // [_FolderCaption]) in whichever pairing the background's brightness
          // calls for, which covers the pale swatches, the dark ones, and an
          // arbitrary gallery photo alike. Obx: repaints the moment a new
          // background is applied.
          Obx(() => _FolderCaption(title: title, onDark: _folderLabelOnDark())),
        ],
      ),
    );
  }

  /// The 2x2 body of the folder. Beyond four icons the last slot becomes a
  /// mini 2x2 of the next four, so a long section still reads as "one folder"
  /// rather than an arbitrary truncation.
  Widget _preview(DiscoverFolderTheme theme) {
    final icons = iconPaths.where((e) => e.trim().isNotEmpty).toList();
    final bool overflows = icons.length > 4;
    final slots = <Widget>[];

    for (int i = 0; i < (overflows ? 3 : 4); i++) {
      slots.add(_DiscoverFolderPlate(
        iconPath: i < icons.length ? icons[i] : null,
        color: theme.plateTint(i),
      ));
    }
    if (overflows) {
      slots.add(_miniGrid(theme, icons.skip(3).take(4).toList()));
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: slots[0]),
              const SizedBox(width: 6),
              Expanded(child: slots[1]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(child: slots[2]),
              const SizedBox(width: 6),
              Expanded(child: slots[3]),
            ],
          ),
        ),
      ],
    );
  }

  /// Last slot when the section has more than four categories: four quarter-size
  /// plates in their own 2x2.
  Widget _miniGrid(DiscoverFolderTheme theme, List<String> icons) {
    Widget cell(int i) => _DiscoverFolderPlate(
          iconPath: i < icons.length ? icons[i] : null,
          // Offset by one so the mini cells don't repeat the tint of the
          // full-size plate they sit next to.
          color: theme.plateTint(i + 1),
          radius: 7,
          padding: 3,
        );
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(0)),
              const SizedBox(width: 3),
              Expanded(child: cell(1)),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Row(
            children: [
              Expanded(child: cell(2)),
              const SizedBox(width: 3),
              Expanded(child: cell(3)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The section title under a folder, drawn with an outline around the letters
/// rather than a soft halo behind them.
///
/// Two passes of the same string in the same style: a stroked one underneath
/// and the filled one on top. Flutter can't do both in one [Text] — [TextStyle]
/// takes `color` OR a `foreground` [Paint], never both — so the border has to be
/// a second layer. Both passes share [_style] and identical layout parameters,
/// which is what keeps them registered on top of each other; changing the
/// alignment, `maxLines` or the font of one without the other would ghost the
/// label.
///
/// The stroke is always the opposite tone to the fill, so it does the whole job
/// of separating the letters from the background: white ringing dark text on the
/// pale backgrounds, dark ringing white text on the dark ones — see
/// [_folderLabelOnDark]. Crisper than the blurred [Shadow] this replaced, which
/// went muddy against a busy banner.
class _FolderCaption extends StatelessWidget {
  const _FolderCaption({required this.title, required this.onDark});

  final String title;

  /// Whether the background under this caption is dark — flips the fill/stroke
  /// pair over.
  final bool onDark;

  /// Ring thickness. Centred on the glyph outline, so half of it eats into the
  /// letter: past ~3 the counters of a bold 'a'/'e' start closing up at this
  /// size.
  static const double _strokeWidth = 3.0;

  /// Shared metrics. Anything that affects layout MUST live here so the two
  /// passes lay out identically — only the paint differs between them.
  TextStyle get _style => TextStyle(
        fontFamily: AppConstants.OpenSans,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w700,
        overflow: TextOverflow.ellipsis,
      );

  @override
  Widget build(BuildContext context) {
    // .tr to match [CustomText], which translates every string it is handed —
    // the callers pass titles that are already localised, but a raw key handed
    // to a folder would otherwise start rendering as the key.
    final text = title.tr;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: _style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _strokeWidth
              // Round joins: mitred corners spike off the diagonals of a 'w'/'y'
              // at this weight.
              ..strokeJoin = StrokeJoin.round
              ..color = onDark ? const Color(0xE6000000) : AppColors.white,
            // Keeps the outlined label lifted off a busy background — the ring
            // gives it an edge, this gives it depth.
            shadows: [
              Shadow(
                color: onDark ? const Color(0x73000000) : const Color(0x40000000),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: _style.copyWith(
            color: onDark ? AppColors.white : AppColors.mainTextColor,
          ),
        ),
      ],
    );
  }
}

/// Whether a folder caption should be drawn light-on-dark.
///
/// The caption sits directly on the app background ([AppHomeBackground]) — the
/// one picked in `AppBackgroundScreen` — which Discover deliberately paints at
/// full strength with nothing dimming it, so the only thing that can guarantee
/// the caption's contrast is the background itself:
///
///  * colour background → its own luminance decides.
///  * bundled banner → every asset in [AppBackgroundController.bannerOptions] is
///    pale artwork, so the caption goes dark.
///  * gallery photo → unknown brightness, so it takes the light-on-dark subtitle
///    treatment (white text, dark halo) — the one pairing that survives a photo
///    of any tone.
///
/// Call from inside an [Obx]: it reads the controller's observables, so the
/// captions re-colour the moment a new background is applied.
bool _folderLabelOnDark() {
  final ctrl = getOrPut(() => AppBackgroundController(), permanent: true);
  final banner = ctrl.bannerAsset.value;
  final color = ctrl.bgColor.value;
  if (banner.isEmpty) return color.computeLuminance() < 0.5;
  return !AppBackgroundController.bannerIsAsset(banner);
}

/// One rounded pastel plate inside a folder, holding a single category icon.
/// Renders empty (but still plate-shaped) when the section has fewer icons than
/// slots or its data hasn't arrived yet.
class _DiscoverFolderPlate extends StatelessWidget {
  const _DiscoverFolderPlate({
    this.iconPath,
    required this.color,
    this.radius = 14,
    this.padding = 6,
  });

  final String? iconPath;

  /// Pastel fill for this slot, from [DiscoverFolderTheme.plateTint].
  final Color color;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: iconPath == null
          ? const SizedBox.shrink()
          : DiscoverFolderIcon(iconPath: iconPath!),
    );
  }
}

/// Category icon that accepts either a bundled asset or a backend URL — the two
/// sources Discover sections mix freely.
class DiscoverFolderIcon extends StatelessWidget {
  const DiscoverFolderIcon({super.key, required this.iconPath});

  final String iconPath;

  @override
  Widget build(BuildContext context) {
    if (isNetworkImage(iconPath)) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        fit: BoxFit.contain,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return LocalAssets(imagePath: iconPath, boxFix: BoxFit.contain);
  }
}

/// Sheet a folder opens into. It hosts the section's ORIGINAL card — same
/// grid, same labels, same tap routing — with [DiscoverFolderScope] switched
/// off so the section renders its normal full-width self inside.
class DiscoverFolderSheet {
  static Future<void> show(
    BuildContext context,
    String title,
    WidgetBuilder builder,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F7FD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Grab handle.
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.greyE5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: SizeConfig.size12,
                        right: SizeConfig.size12,
                        bottom: SizeConfig.size24,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        // Scope off: the section renders its normal card here,
                        // with every tap routing exactly as before.
                        child: DiscoverFolderScope(
                          enabled: false,
                          child: Builder(builder: builder),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
