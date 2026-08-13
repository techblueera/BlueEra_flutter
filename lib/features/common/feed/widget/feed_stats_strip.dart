import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

/// One entry in a [FeedStatsStrip]: a glyph and its count.
///
/// A null [onTap] makes the entry read-only — that is deliberate for the
/// timestamp and the view count, which are information rather than actions and
/// must not fall through to the card's own "open detail" tap.
class FeedStatItem {
  const FeedStatItem({
    required this.iconPath,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  final String iconPath;

  /// Empty renders the glyph alone — the design's share button has no count.
  final String label;

  /// Overrides the default muted tint; used to light the like glyph up in the
  /// brand colour once the viewer has liked the post.
  final Color? iconColor;

  final VoidCallback? onTap;
}

/// The tinted engagement bar along the bottom of a feed card.
///
/// The fill is a low-alpha black rather than a fixed grey so the bar works on
/// both card treatments: it reads as the design's light grey on a solid white
/// card, and stays translucent inside a [GlassScope] card without punching an
/// opaque block through the frost.
class FeedStatsStrip extends StatelessWidget {
  const FeedStatsStrip({
    super.key,
    required this.items,
    this.padding,
    this.spread = true,
  });

  final List<FeedStatItem> items;

  /// Outer padding, so a caller can cancel an inherited asymmetric inset.
  final EdgeInsetsGeometry? padding;

  /// Whether the entries fill the bar edge to edge.
  ///
  /// True suits the post card, whose six entries earn the full width. A poll
  /// carries only three, and spreading those leaves two ragged gaps — so it
  /// clusters them to the left instead, as the design shows.
  final bool spread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size12,
          vertical: SizeConfig.size8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              spread ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (!spread && i > 0) SizedBox(width: SizeConfig.size20),
              // Spread mode lets an entry shrink so a long "11 months ago"
              // cannot overflow a crowded bar; clustered mode leaves them at
              // their natural width so the gaps stay even.
              if (spread)
                Flexible(child: _buildItem(item: items[i]))
              else
                _buildItem(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItem({required FeedStatItem item}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(
          imagePath: item.iconPath,
          width: SizeConfig.size18,
          height: SizeConfig.size18,
          imgColor: item.iconColor ?? AppColors.secondaryTextColor,
        ),
        if (item.label.isNotEmpty) ...[
          SizedBox(width: SizeConfig.size4),
          // Flexible so a long timestamp ("11 months ago") shortens instead of
          // overflowing the row on a narrow screen.
          Flexible(
            child: CustomText(
              item.label,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w500,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    if (item.onTap == null) {
      // Absorb the tap so an informational entry can't trigger the card's
      // open-detail gesture underneath it.
      return GestureDetector(onTap: () {}, child: content);
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}
