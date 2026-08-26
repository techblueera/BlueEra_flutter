import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/discover_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The plate a Discover tile draws behind its icon.
///
/// Two shapes, picked by the icon itself:
///
///  * **Bare icon** (legacy bundled art, or a `/category` image URL) — the
///    original soft circle in `#F2F6FF` with 14% padding. Those PNGs are
///    transparent cut-outs and look unanchored without something behind them.
///  * **[DiscoverIcons] tile** — nothing at all, icon edge-to-edge. That set
///    ships its artwork already sitting on a tinted rounded-square, so drawing
///    the circle too leaves a coloured square overhanging a blue disc, with the
///    disc poking out at the four corners.
///
/// Keeping the decision here (rather than at the ~15 call sites) is what lets a
/// section mix both kinds while a vertical is mid-migration — which several
/// are, since the API-fed sections can't move until the new art is uploaded
/// backend-side. See `docs/discover_dynamic_icons.txt`.
class DiscoverTilePlate extends StatelessWidget {
  const DiscoverTilePlate({
    super.key,
    required this.iconPath,
    required this.diameter,
    required this.child,
  });

  final String iconPath;
  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // [DiscoverIcons.fillsTile], not `isSelfContained`: a `/category` URL is
    // artwork that already carries its own square, and plating it left the
    // Grocery and Food tiles ringed with blank space while every bundled
    // section beside them filled edge to edge.
    if (DiscoverIcons.fillsTile(iconPath)) {
      return SizedBox(width: diameter, height: diameter, child: child);
    }
    return Container(
      width: diameter,
      height: diameter,
      padding: EdgeInsets.all(diameter * 0.14),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF2F6FF),
      ),
      child: child,
    );
  }
}

/// One category inside an opened folder — the big tile in the picker sheet.
///
/// ## Why there is no card around it
///
/// The tile IS the artwork: a rounded square with the label underneath it,
/// outside. That is the same object model the folder metaphor already set up on
/// the landing grid, and it is what buys the illustration its size — at three
/// columns the art lands around 105px, where a shopfront actually reads as a
/// shopfront. Wrapping it in a card would spend a quarter of that width on
/// chrome that says nothing.
///
/// A network icon still gets a plate, for the same reason [DiscoverTilePlate]
/// gives one: those are transparent cut-outs, and a cut-out with nothing behind
/// it floats. Bundled [DiscoverIcons] art ships its own tinted square and fills
/// the tile edge to edge.
class DiscoverSheetTile extends StatefulWidget {
  const DiscoverSheetTile({
    super.key,
    required this.name,
    required this.iconPath,
    required this.onTap,
  });

  final String name;
  final String iconPath;
  final VoidCallback onTap;

  @override
  State<DiscoverSheetTile> createState() => _DiscoverSheetTileState();
}

class _DiscoverSheetTileState extends State<DiscoverSheetTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // The sheet deliberately STAYS OPEN behind the destination, so the user
      // comes back to the folder they were picking from. Keeping it tappable
      // across that round trip is [DiscoverFolderSheet]'s job — see the
      // remount-on-return wrapper there.
      onTap: widget.onTap,
      // Press feedback lives on the tile itself because there is no card and no
      // ink surface to ripple — without it a tap on a picker has no answer
      // until the next screen arrives.
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: Semantics(
        button: true,
        label: widget.name,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _artwork(),
              ),
              const SizedBox(height: 6),
              // Self-sizing, NOT a fixed two-line box. Reserving two lines kept
              // the rows on one rhythm, but most category names are one line —
              // so every tile carried a blank line under it, which stacked with
              // the row gap into the dead band the grid was showing between
              // rows. A row is only as tall as its own tallest label now; the
              // Row aligns its tiles at the top, so nothing looks ragged.
              CustomText(
                widget.name,
                textAlign: TextAlign.center,
                fontSize: 12,
                height: 1.25,
                color: const Color(0xFF26313F),
                fontWeight: FontWeight.w600,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artwork() {
    final path = widget.iconPath;
    final borderRadius = BorderRadius.circular(20);

    if (DiscoverIcons.fillsTile(path)) {
      // Ships its own tinted square — let it be the tile. Network art takes
      // this path too, at `contain` rather than `cover`, so a category that is
      // still a bare cut-out scales inside the slot instead of being cropped.
      return ClipRRect(
        borderRadius: borderRadius,
        child: DiscoverIcons.isNetwork(path)
            ? CachedNetworkImage(
                imageUrl: path,
                fit: DiscoverIcons.fitFor(path),
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.secondaryTextColor,
                  size: 22,
                ),
              )
            : LocalAssets(imagePath: path, boxFix: BoxFit.cover),
      );
    }

    // Thin margin, not a generous one. Much of the `/category` art already has
    // its own tinted rounded square baked in (see docs/discover_dynamic_icons
    // .txt §3) — at 18px of padding that square sat marooned in the middle of a
    // white card with a visible moat around it. 8px reads as a rim on the
    // baked-square art and still gives a transparent cut-out room to breathe.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFFE4EAF2), width: 1),
      ),
      child: path.isEmpty
          ? const SizedBox.shrink()
          : isNetworkImage(path)
              ? CachedNetworkImage(
                  imageUrl: path,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.secondaryTextColor,
                    size: 22,
                  ),
                )
              : LocalAssets(imagePath: path, boxFix: BoxFit.contain),
    );
  }
}

/// Overrides how many columns [DiscoverSheetGrid] runs, for the subtree under
/// it. Absent — the v1 folder sheet — means [kDiscoverSheetColumns].
class DiscoverSheetColumnsScope extends InheritedWidget {
  const DiscoverSheetColumnsScope({
    super.key,
    required this.columns,
    required super.child,
  });

  final int columns;

  static int? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DiscoverSheetColumnsScope>()
      ?.columns;

  @override
  bool updateShouldNotify(DiscoverSheetColumnsScope oldWidget) =>
      columns != oldWidget.columns;
}

/// The picker grid inside an opened folder: [kDiscoverSheetColumns] per row.
///
/// Plain rows rather than a GridView — the sheet already scrolls, and rows of
/// Expanded children need no aspect-ratio arithmetic to stay square. A short
/// last row keeps its slots instead of stretching to fill the width.
class DiscoverSheetGrid extends StatelessWidget {
  const DiscoverSheetGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  /// Columns for THIS grid: whatever an enclosing [DiscoverSheetColumnsScope]
  /// asks for, else the shared default.
  ///
  /// Discover v2's group sheet packs three sub-sections into one sheet
  /// (Grocery / Restaurants & Food / Home Made Food), so it runs four across to
  /// keep each section to a row or two — see `discover_group_sheet_v2.dart`.
  /// The v1 folder sheet shows one section with the screen to itself and stays
  /// at three.
  int _columns(BuildContext context) =>
      DiscoverSheetColumnsScope.of(context) ?? kDiscoverSheetColumns;

  static const double _gap = 12;

  /// Vertical gap between rows. Small, because the labels now size themselves —
  /// with a fixed label box this had to carry the whole separation and the two
  /// together left a band of empty page between every row.
  static const double _rowGap = 14;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    final columns = _columns(context);
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += columns) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: _gap),
            Expanded(
              child: i + c < tiles.length
                  ? tiles[i + c]
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: _rowGap),
          rows[r],
        ],
      ],
    );
  }
}

/// A single round category tile: an illustrated icon inside a soft circular
/// background with a 2-line label below. Mirrors the tiles in the Discover
/// redesign (Grocery / Food sections).
class DiscoverCircleTile extends StatelessWidget {
  final CollapsibleGridModel item;
  final VoidCallback onTap;
  final double diameter;

  const DiscoverCircleTile({
    super.key,
    required this.item,
    required this.onTap,
    this.diameter = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiscoverTilePlate(
            iconPath: item.icon ?? '',
            diameter: diameter,
            child: LocalAssets(
              imagePath: item.icon ?? '',
              boxFix: DiscoverIcons.fitFor(item.icon),
            ),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            item.name,
            textAlign: TextAlign.center,
            // Same 10 / regular / secondary as the chip rows and
            // [DiscoverIconTile] — one label style for every category.
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Section header (bold title on the left, optional "View All" on the right)
/// followed by a grid of [DiscoverCircleTile]s laid out [columns]-per-row.
///
/// Used for the Grocery and Food blocks of the redesigned Discover page.
class DiscoverCategorySection extends StatelessWidget {
  final String title;
  final List<CollapsibleGridModel> items;
  final int columns;
  final void Function(CollapsibleGridModel item) onItemTap;
  final VoidCallback? onViewAll;

  /// Tapping this section's folder tile in the landing grid opens this directly
  /// instead of the sheet — see [DiscoverFolderTile.onTap]. Only affects folder
  /// mode; the full card is unchanged.
  final VoidCallback? onFolderTap;

  const DiscoverCategorySection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.columns = 5,
    this.onViewAll,
    this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    // Inside an opened folder: the picker grid, no card and no title — the
    // sheet supplies both. See [DiscoverSheetScope].
    if (DiscoverSheetScope.isActive(context)) {
      return DiscoverSheetGrid(
        tiles: [
          for (final item in items)
            DiscoverSheetTile(
              name: item.name,
              iconPath: item.icon ?? '',
              onTap: () => onItemTap(item),
            ),
        ],
      );
    }
    // Landing grid (see [DiscoverFolderScope]): collapse to a folder tile whose
    // sheet re-renders this very card, so routing below is untouched.
    if (DiscoverFolderScope.isActive(context)) {
      // Prefer the owning section widget so the sheet gets a live instance of
      // it — see [DiscoverFolderHost]. Falls back to this card when the section
      // IS this widget (grocery / food / home services are listed directly).
      final host = DiscoverFolderHost.sectionOf(context);
      return DiscoverFolderTile(
        title: title,
        iconPaths: items.map((e) => e.icon ?? '').toList(),
        expandedBuilder: (_) => host ?? _fullCard(),
        onTap: onFolderTap,
      );
    }
    return _fullCard();
  }

  Widget _fullCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),

        color: AppColors.white,

      ),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.large18,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onViewAll != null) ViewAllButton(onTap: onViewAll!),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 8;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: SizeConfig.size16,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: DiscoverCircleTile(
                          item: item,
                          diameter: itemWidth * 0.9,
                          onTap: () => onItemTap(item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A single round category tile that reads its label + icon from raw strings
/// (rather than a [CollapsibleGridModel]). Supports both bundled asset icons
/// and network URLs, so every Discover service section can share the same
/// circular look regardless of where its icon comes from.
class DiscoverIconTile extends StatelessWidget {
  final String name;
  final String iconPath;
  final VoidCallback onTap;
  final double diameter;

  const DiscoverIconTile({
    super.key,
    required this.name,
    required this.iconPath,
    required this.onTap,
    this.diameter = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiscoverTilePlate(
            iconPath: iconPath,
            diameter: diameter,
            child: _buildIcon(),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            name,
            textAlign: TextAlign.center,
            // 10 / regular / secondary — the SAME label style the chip rows
            // use, so a category reads identically whether it is a chip on the
            // page or a tile inside a folder.
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (iconPath.isEmpty) return const SizedBox.shrink();
    final fit = DiscoverIcons.fitFor(iconPath);
    if (isNetworkImage(iconPath)) {
      return CachedNetworkImage(
        imageUrl: iconPath,
        fit: fit,
        // Fill the slot [DiscoverTilePlate] hands over. Without these the image
        // lays out at its intrinsic size and floats in the middle — the same
        // blank ring the plate used to draw, minus the plate.
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.secondaryTextColor,
          size: 20,
        ),
      );
    }
    return LocalAssets(imagePath: iconPath, boxFix: fit);
  }
}

/// Generic version of [DiscoverCategorySection] for the redesigned Discover
/// service sections. Renders a bold title (+ optional "View All") over a grid
/// of circular [DiscoverIconTile]s, [columns]-per-row, reading each tile's
/// label / icon / tap from the supplied callbacks so any model type can be
/// laid out with the same look while its existing routing stays untouched.
class DiscoverGridSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int columns;
  final String Function(T item) getName;
  final String Function(T item) getIcon;
  final void Function(T item) onItemTap;
  final VoidCallback? onViewAll;
  final String? viewAllLabel;

  /// Tapping this section's folder tile in the landing grid opens this directly
  /// instead of the sheet — see [DiscoverFolderTile.onTap]. Only affects folder
  /// mode; the full card is unchanged.
  ///
  /// Note this is NOT [onViewAll]: on the sections that page their grid
  /// ("Shopping & Sales", "Book Home Services") that link is a Show more/less
  /// toggle, which would be meaningless as a folder destination.
  final VoidCallback? onFolderTap;

  const DiscoverGridSection({
    super.key,
    required this.title,
    required this.items,
    required this.getName,
    required this.getIcon,
    required this.onItemTap,
    this.columns = 5,
    this.onViewAll,
    this.viewAllLabel,
    this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    // See [DiscoverCategorySection.build] — same picker grid, same reason. The
    // paging sections ("Shopping & Sales", "Book Home Services") deliberately
    // pass their CAPPED list here too: the folder preview counted the same
    // list, and a sheet that silently held more than the header promised would
    // be the header lying.
    if (DiscoverSheetScope.isActive(context)) {
      return DiscoverSheetGrid(
        tiles: [
          for (final item in items)
            DiscoverSheetTile(
              name: getName(item),
              iconPath: getIcon(item),
              onTap: () => onItemTap(item),
            ),
        ],
      );
    }
    // See [DiscoverCategorySection.build] — same folder collapse, same reason.
    if (DiscoverFolderScope.isActive(context)) {
      final host = DiscoverFolderHost.sectionOf(context);
      return DiscoverFolderTile(
        title: title,
        iconPaths: items.map(getIcon).toList(),
        expandedBuilder: (_) => host ?? _fullCard(),
        onTap: onFolderTap,
      );
    }
    return _fullCard();
  }

  Widget _fullCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  title,
                  fontSize: SizeConfig.large18,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onViewAll != null)
                ViewAllButton(onTap: onViewAll!, label: viewAllLabel),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 8;
              final double itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: SizeConfig.size16,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: DiscoverIconTile(
                          name: getName(item),
                          iconPath: getIcon(item),
                          diameter: itemWidth * 0.9,
                          onTap: () => onItemTap(item),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
