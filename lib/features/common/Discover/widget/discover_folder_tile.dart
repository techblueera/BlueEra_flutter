import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/discover_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/app_background_controller.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
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

/// Columns the category grid uses inside an opened folder.
///
/// Three, against the five the landing card uses. The card is a preview strip
/// competing with fourteen others for a screen; the sheet is a picker with the
/// screen to itself, and it is the only place the illustrated artwork is ever
/// seen at a size where you can tell one shop type from another. Five columns
/// left each tile ~58px with an 11px label wrapping to two lines — three gives
/// it ~105px.
const int kDiscoverSheetColumns = 3;

/// Marks the subtree inside an opened folder's sheet.
///
/// Presence alone is the signal — a section that finds this renders as a bare
/// PICKER GRID (see `DiscoverSheetTile`) rather than as its landing card: no
/// white card, no title, no "View All", just the categories at a size worth
/// tapping. The chrome around them belongs to [DiscoverFolderSheet], which
/// already knows the title it was opened with; a section drawing its own
/// produced the same heading twice, on two stacked surfaces.
class DiscoverSheetScope extends InheritedWidget {
  const DiscoverSheetScope({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiscoverSheetScope>() != null;

  @override
  bool updateShouldNotify(DiscoverSheetScope oldWidget) => false;
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
  DiscoverFolderHost({
    super.key,
    required this.section,
    this.index = 0,
    this.title,
  }) : super(child: section);

  final Widget section;

  /// Caption for the tile, when the section's own title is not what the grid
  /// should say. Discover v2 uses it for the two sections whose full names run
  /// past a half-width tile and ellipsise ("Automotive Showroom & Services",
  /// "Education, Training & Sectors"); the SHEET still opens under the
  /// section's own title, which is where the longer name belongs.
  final String? title;

  static String? titleOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DiscoverFolderHost>()
      ?.title;

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
      section != oldWidget.section ||
      index != oldWidget.index ||
      title != oldWidget.title;
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
    this.expandedBuilder,
    this.onTap,
  }) : assert(expandedBuilder != null || onTap != null,
            'A folder must either open a sheet or route somewhere');

  final String title;

  /// Icons previewed inside the folder, in section order. Asset paths and
  /// network URLs are both accepted (Discover mixes bundled illustrations with
  /// backend category images).
  final List<String> iconPaths;

  /// The section exactly as it renders outside folder mode — shown in the sheet
  /// when the folder is opened. Ignored when [onTap] is given.
  final WidgetBuilder? expandedBuilder;

  /// Skips the sheet entirely and runs this instead. For sections whose card is
  /// only a launcher for one destination, the sheet is a step with nothing in
  /// it — the folder goes straight to the screen.
  final VoidCallback? onTap;

  /// The folder's own surface: ONE frosted plate, identical for every folder.
  ///
  /// Each folder used to carry its own hue (see `discover_folder_palette.dart`),
  /// which turned the grid into fourteen different coloured cards competing with
  /// the illustrated icons on them and with the user's background behind them.
  /// The reference (`assets/discover_tab.jpeg`) is the iOS App Library: every
  /// folder is the same neutral glass, and what identifies one is the icons
  /// inside it, not the colour of the box.
  ///
  /// The recipe itself — fill, blur, rim, lift, radius, and WHY each is the
  /// value it is — lives in `discover_glass.dart`, because the header banner and
  /// the recent-orders rail paint themselves with the same one. It used to be
  /// copied per call site, which is how two panels on one page end up a shade
  /// apart after someone tunes one of them.
  /// Fill, blur, rim and radius are now read per-subtree from
  /// [DiscoverSurfaceTheme] — v1 finds no scope and gets these same constants
  /// back, v2 hands down its own. The lift is shared by both looks.
  static const List<BoxShadow> _kTileShadow = kDiscoverGlassShadow;

  /// Plate behind each icon — a brighter white than the tile it sits on, so the
  /// illustrated icons keep a clean base and the 2x2 reads as four slots rather
  /// than one wash.
  static const Color _kPlateFill = kDiscoverGlassPlateFill;

  @override
  Widget build(BuildContext context) {
    // v2 hands its own fill / stroke / blur down the tree; v1 finds no scope
    // and reads the constants — see [DiscoverSurfaceTheme].
    final fill = DiscoverSurfaceTheme.fillOf(context);
    final border = DiscoverSurfaceTheme.borderOf(context);
    final blur = DiscoverSurfaceTheme.blurOf(context);
    final radius = DiscoverSurfaceTheme.radiusOf(context);
    final label = DiscoverFolderHost.titleOf(context) ?? title;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ??
          () => DiscoverFolderSheet.show(context, title, expandedBuilder!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            // Shadow OUTSIDE the clip: a ClipRRect crops its child, so a
            // boxShadow declared inside it is clipped away with everything else
            // past the rounded edge.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: _kTileShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // Translucent, so the folder keeps picking up whatever it
                      // sits on — the background is unchanged, only the tile
                      // over it is.
                      color: fill,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: _preview(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          // The label sits on the app background, not on the tile, so it has no
          // plate of its own to borrow contrast from — and the page no longer
          // dims that background. It therefore draws itself OUTLINED (see
          // [_FolderCaption]) in whichever pairing the background's brightness
          // calls for, which covers the pale swatches, the dark ones, and an
          // arbitrary gallery photo alike. Obx: repaints the moment a new
          // background is applied.
          Obx(() => _FolderCaption(title: label, onDark: _folderLabelOnDark())),
        ],
      ),
    );
  }

  /// The 2x2 body of the folder. Beyond four icons the last slot becomes a
  /// mini 2x2 of the next four, so a long section still reads as "one folder"
  /// rather than an arbitrary truncation.
  Widget _preview() {
    final icons = iconPaths.where((e) => e.trim().isNotEmpty).toList();
    final bool overflows = icons.length > 4;
    final slots = <Widget>[];

    for (int i = 0; i < (overflows ? 3 : 4); i++) {
      slots.add(_DiscoverFolderPlate(
        iconPath: i < icons.length ? icons[i] : null,
        color: _kPlateFill,
      ));
    }
    if (overflows) {
      slots.add(_miniGrid(icons.skip(3).take(4).toList()));
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
  Widget _miniGrid(List<String> icons) {
    Widget cell(int i) => _DiscoverFolderPlate(
          iconPath: i < icons.length ? icons[i] : null,
          color: _kPlateFill,
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
        fontSize: SizeConfig.small,
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

  /// Fill behind the icon — one translucent white for every slot in every
  /// folder, so the grid reads as one material.
  final Color color;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    // [DiscoverIcons] art already sits on its own tinted rounded-square, so it
    // fills the slot edge-to-edge and the translucent plate is dropped —
    // otherwise the folder shows a coloured square inset inside a white one.
    // `/category` URLs now count too: most of that art carries its own square
    // as well, and plating it was what left the Grocery and Food folders ringed
    // with blank space. Only legacy bundled cut-outs still take the plate. Same
    // rule as [DiscoverTilePlate] — see [DiscoverIcons.fillsTile].
    if (DiscoverIcons.fillsTile(iconPath)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DiscoverFolderIcon(iconPath: iconPath!),
      );
    }
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
    // Self-contained art fills the slot; a cut-out is contained. See
    // [DiscoverIcons.fitFor].
    final fit = DiscoverIcons.fitFor(iconPath);
    if (isNetworkImage(iconPath)) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        fit: fit,
        // Fill the slot the plate used to define. Without these the image is
        // laid out at its intrinsic size and floats in the middle — the same
        // blank ring the plate was drawing, just without the plate.
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return LocalAssets(imagePath: iconPath, boxFix: fit);
  }
}

/// Rebuilds its subtree from scratch once a route that was pushed OVER this
/// one has gone away again.
///
/// Why the folder sheet needs it: the sheet deliberately stays open behind the
/// screen a category opens, so the user comes back to the picker they were
/// using. But the grid came back DEAD — still painted, no longer taking taps —
/// and only dismissing and reopening the sheet fixed it. Dismiss-and-reopen is
/// simply "build this content again", which is what this does without throwing
/// the sheet away: state stranded in the picker's elements by the round trip is
/// discarded and the grid is live again.
///
/// [ModalRoute.secondaryAnimation] is the signal — it runs forward when
/// something covers this route and back to `dismissed` when that something is
/// gone. Every Discover route lives on the one root navigator (there is no
/// nested Navigator under the bottom bar), so the sheet really does see the
/// pushes that cover it.
///
/// Scoped to the CONTENT, not the whole sheet: it sits inside the
/// [SingleChildScrollView], so the scroll position and the sheet's own drag
/// extent survive untouched and the folder does not visibly flinch. Section
/// state inside is reset, which costs nothing here — in sheet mode the sections
/// render an uncapped, stateless picker grid (their "Show more" toggles are
/// deliberately not built).
class _RemountOnUncover extends StatefulWidget {
  const _RemountOnUncover({required this.child});

  final Widget child;

  @override
  State<_RemountOnUncover> createState() => _RemountOnUncoverState();
}

class _RemountOnUncoverState extends State<_RemountOnUncover> {
  Animation<double>? _secondary;

  /// Bumped on every uncover; used as the subtree key, so a change forces a
  /// full rebuild rather than an update-in-place.
  int _generation = 0;

  /// Only remount if something actually covered us. Without this, the
  /// `dismissed` status the animation already sits at would count as a return
  /// trip and remount the grid the moment the sheet opened.
  bool _wasCovered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (identical(secondary, _secondary)) return;
    _secondary?.removeStatusListener(_onSecondaryStatus);
    _secondary = secondary;
    _secondary?.addStatusListener(_onSecondaryStatus);
  }

  void _onSecondaryStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
      case AnimationStatus.completed:
        _wasCovered = true;
      case AnimationStatus.dismissed:
        if (!_wasCovered) return;
        _wasCovered = false;
        if (mounted) setState(() => _generation++);
      case AnimationStatus.reverse:
        break;
    }
  }

  @override
  void dispose() {
    _secondary?.removeStatusListener(_onSecondaryStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<int>(_generation),
      child: widget.child,
    );
  }
}

/// Sheet a folder opens into — the category picker.
///
/// It mounts the section's own widget (so every tap routes exactly as it did on
/// the landing card) but under [DiscoverSheetScope], which makes that section
/// render as a bare 3-column grid. The heading, the count and the close control
/// belong to the sheet: it is the thing that was opened, so it is the thing
/// that should name itself.
///
/// The field colour is the same `#F3F7FD` the sheet always used. It is what
/// makes this read as the folder OPENING rather than as a modal arriving over
/// it — and it is now the only surface here. Previously a white card sat on top
/// of it carrying a second copy of the title, which is two panels and two
/// headings to say one thing.
class DiscoverFolderSheet {
  static const Color _field = Color(0xFFF3F7FD);
  static const Color _ink = Color(0xFF0F1722);
  static const Color _inkSoft = Color(0xFF5D6B7C);

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
          // Opens tall enough that two full rows of the 3-column grid are on
          // screen without a drag — at 0.6 the third row was cut mid-artwork,
          // which reads as "there is nothing more" rather than "scroll".
          initialChildSize: 0.68,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: _field,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Grab handle.
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  _header(sheetContext, title),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        SizeConfig.size16,
                        SizeConfig.size4,
                        SizeConfig.size16,
                        SizeConfig.size24 +
                            MediaQuery.of(sheetContext).padding.bottom,
                      ),
                      // Folder scope OFF (don't render another folder tile),
                      // sheet scope ON (render as the picker grid).
                      //
                      // Wrapped so the grid comes back ALIVE after the user
                      // opens a category and returns — see [_RemountOnUncover].
                      child: _RemountOnUncover(
                        child: DiscoverFolderScope(
                          enabled: false,
                          child: DiscoverSheetScope(
                            child: Builder(builder: builder),
                          ),
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

  /// Title and the way out.
  ///
  /// A category COUNT was tried here and cut. The only number available to the
  /// sheet is the one the landing card previewed, and the sheet deliberately
  /// shows more than that card does (the paging sections drop their cap in
  /// here) — so the count would have contradicted the grid under it. A heading
  /// that has to be qualified is worse than no second line.
  static Widget _header(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size6,
        SizeConfig.size10,
        SizeConfig.size12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: CustomText(
              title,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          // Explicit close, because the sheet opens tall — reaching the handle
          // to dismiss means crossing the whole grid with your thumb.
          Semantics(
            button: true,
            label: 'Close',
            child: InkResponse(
              onTap: () => Navigator.of(context).maybePop(),
              radius: 24,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8EEF7),
                ),
                child: const Icon(Icons.close_rounded, size: 18, color: _inkSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
