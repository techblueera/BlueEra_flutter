import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_category_section.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_folder_tile.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// One titled run of categories inside a v2 group sheet — "Grocery",
/// "Restaurants & Food", "Home Made Food" in `assets/img_3.png`.
///
/// [section] is the EXISTING Discover section widget, mounted unchanged. That
/// is the whole point of the merge: the sheet supplies the heading and the
/// layout, while every tile keeps the artwork, the category ids and the tap
/// routing its own section already defines. Nothing here re-implements a
/// destination, so a route that changes in the section changes here too.
class DiscoverGroupSubSection {
  const DiscoverGroupSubSection({required this.title, required this.section});

  /// Heading above the grid. Already localised by the caller.
  final String title;

  /// The section widget, rendered as a picker grid (see [DiscoverSheetScope]).
  final Widget section;
}

/// The sheet a v2 folder opens: one or more [DiscoverGroupSubSection]s stacked
/// under a single title.
///
/// v1 gave every section its own folder, so its sheet only ever had one grid in
/// it and needed no headings. v2 merges the related ones — Grocery + Restaurants
/// + Home Made Food behind "Grocery & Food", Home Made Product + Shopping behind
/// "Shopping", Home + Business services behind "Find Services" — which is what
/// the headings are for: without them the merged sheet is one undifferentiated
/// wall of tiles and the user cannot tell a restaurant from a tiffin service.
class DiscoverGroupSheetV2 {
  /// Sheet surface. Flat white, unlike v1's tinted `_field`: the reference is a
  /// white card floating over a dimmed page, and the grids inside carry their
  /// own plates, so a tint here only greys the artwork.
  static const Color _surface = AppColors.white;
  static const Color _ink = Color(0xFF0F1722);

  /// Four across, against v1's three — see [DiscoverSheetColumnsScope]. Three
  /// sub-sections in one sheet means three headings competing for the same
  /// screen; at three columns the third heading is always below the fold.
  static const int _columns = 4;

  static Future<void> show(
    BuildContext context,
    String title,
    List<DiscoverGroupSubSection> sections,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          // Tall on open: the reference sheet shows all three headings at once,
          // which is what tells the user this is a merged picker rather than
          // the one grid v1 opened.
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _header(sheetContext, title),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        SizeConfig.size16,
                        0,
                        SizeConfig.size16,
                        SizeConfig.size24 +
                            MediaQuery.of(sheetContext).padding.bottom,
                      ),
                      // Folder scope OFF (a section inside the sheet must not
                      // collapse into another folder tile), sheet scope ON (so
                      // each section renders as its picker grid), four columns
                      // for the whole subtree.
                      child: DiscoverFolderScope(
                        enabled: false,
                        child: DiscoverSheetScope(
                          child: DiscoverSheetColumnsScope(
                            columns: _columns,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final s in sections) ...[
                                  _subSectionTitle(s.title),
                                  s.section,
                                  SizedBox(height: SizeConfig.size20),
                                ],
                              ],
                            ),
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

  /// Title on the left, dismiss on the right — the reference's header.
  static Widget _header(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size18,
        SizeConfig.size8,
        SizeConfig.size12,
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.large18,
              fontWeight: FontWeight.w700,
              color: _ink,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: _ink, size: 24),
            splashRadius: 22,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }

  static Widget _subSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size12),
      child: CustomText(
        title,
        fontSize: SizeConfig.large,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    );
  }
}
