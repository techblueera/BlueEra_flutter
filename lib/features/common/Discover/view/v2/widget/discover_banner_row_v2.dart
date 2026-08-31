import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_glass.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One chip on a [DiscoverBannerRowV2] — a category, its artwork, and where it
/// goes.
class DiscoverBannerChip {
  const DiscoverBannerChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;

  /// Asset path or URL. Empty renders the chip as a label alone rather than
  /// leaving a hole where the icon would be.
  final String icon;

  final VoidCallback onTap;
}

/// The full-width rows in the v2 Discover design (`assets/img.png`): a round
/// illustration, a title, and the section's categories as tappable chips —
/// Book Your Transport, Book Your Home Services, Professional Consultant,
/// Financial Services, Find Jobs Near You.
///
/// Why these five are chips while the other eight are folder tiles: each of
/// them is a section the user enters by *naming a thing they already want*
/// ("plumber", "loan", "part-time"), and a chip can carry that name at a size
/// worth reading. The folder sections are browsed by picture instead — you
/// recognise a category by its artwork before you read it — which is what the
/// 2x2 preview is for. Same data, same routes, two presentations.
class DiscoverBannerRowV2 extends StatelessWidget {
  const DiscoverBannerRowV2({
    super.key,
    required this.title,
    required this.chips,
    this.leadingIcon,
    this.onTap,
    this.maxLines = 2,
    this.ctaLabel,
    this.ctaHint,
    this.onCta,
  });

  final String title;
  final List<DiscoverBannerChip> chips;

  /// Artwork for the round leading plate. Falls back to the first chip's icon,
  /// so a section always has something there.
  final String? leadingIcon;

  /// Tapping the row itself (the title, the plate, or the "More" chip) — the
  /// section's own entry point.
  final VoidCallback? onTap;

  /// How many LINES of chips the row may run to before the rest collapse behind
  /// "More" — measured, not a guess at a chip count (see [_ChipLines]).
  ///
  /// The design gives Transport a single line and the others two. A count-based
  /// cap cannot do that: "Bike" and "Digital Marketing" are the same one chip
  /// and nothing like the same width, so whichever number fits one section
  /// overflows or under-fills the next.
  final int maxLines;

  /// Optional call to action under the chips — "Quick Apply For Loan",
  /// "Create Resume" in the design.
  final String? ctaLabel;

  /// Optional line before the CTA ("Need Money?").
  final String? ctaHint;

  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    // An explicit [leadingIcon] is purpose-drawn plate artwork; the fallback is
    // a category icon borrowed off the first chip. They are framed differently
    // — see [_LeadingPlate.fullBleed].
    final hasPlateArt = leadingIcon?.trim().isNotEmpty == true;
    final plateIcon = hasPlateArt ? leadingIcon!.trim() : chips.first.icon;
    final fill = DiscoverSurfaceTheme.fillOf(context);
    final border = DiscoverSurfaceTheme.borderOf(context);
    final blur = DiscoverSurfaceTheme.blurOf(context);
    final radius = DiscoverSurfaceTheme.radiusOf(context);
    final strokeWidth = DiscoverSurfaceTheme.strokeWidthOf(context);
    final shadow = DiscoverSurfaceTheme.shadowOf(context);

    // Same surface as the folder tiles — the row has to read as a sibling of
    // the grid it is interleaved with, not as a different component.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border, width: strokeWidth),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LeadingPlate(
                    icon: plateIcon, fullBleed: hasPlateArt, onTap: onTap),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: CustomText(
                          title,
                          // 16 / w600, as specified — the card titles across
                          // the page are one type style.
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ChipLines(
                        chips: chips,
                        maxLines: maxLines,
                        onMore: onTap,
                      ),
                      if (ctaLabel != null) ...[
                        const SizedBox(height: 8),
                        _Cta(label: ctaLabel!, hint: ctaHint, onTap: onCta),
                      ],
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
}

/// Chip metrics. One place, because [_ChipLines] has to MEASURE a chip before
/// it can lay one out, and a measurement that disagrees with the widget is a
/// row that overflows by exactly the difference.
class _ChipMetrics {
  static const double hPad = 7;
  static const double vPad = 5;
  static const double gap = 6;
  static const double iconSize = 13;
  static const double iconGap = 4;
  static const double radius = 7;

  /// "More" is a word, not a chip: no fill, no border, and a far tighter pad
  /// than [hPad] so it takes only the width of the word itself. It is the tail
  /// of the line, so every px it holds is a px a real category could have had.
  static const double moreHPad = 2;

  /// 10 / regular, in secondary ink — the chips are the row's category LIST,
  /// not its headline, so they sit a clear step under the 16 / w600 title. At
  /// this size more of them fit per line, so fewer fall behind "More".
  static double fontSize() => SizeConfig.extraSmall;

  static TextStyle labelStyle() => TextStyle(
        fontFamily: AppConstants.OpenSans,
        fontSize: fontSize(),
        fontWeight: FontWeight.w400,
      );

  /// "More" is [labelStyle] one step up — same family, same regular weight,
  /// 11 instead of 10. [moreWidth] and [_MoreChip] MUST both read this: a
  /// measurement taken in a different size reserves a width the chip never
  /// draws, and that gap is exactly the bug this file already had once.
  static TextStyle moreStyle() =>
      labelStyle().copyWith(fontSize: SizeConfig.small11);

  /// Rendered width of one chip, including its padding and icon.
  static double width(DiscoverBannerChip chip) {
    final painter = TextPainter(
      text: TextSpan(text: chip.label.tr, style: labelStyle()),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final icon = chip.icon.trim().isEmpty ? 0.0 : (iconSize + iconGap);
    return painter.width + icon + hPad * 2 + 2; // +2 for the 1px border
  }

  /// Width of the trailing "More" affordance. Measured in the EXACT style
  /// _MoreChip renders — same face, same pad — because measuring wider than it
  /// draws reserves room the chip never uses, and that is empty space on the
  /// end of the line.
  static double moreWidth() {
    final painter = TextPainter(
      text: TextSpan(
        text: AppStrings.more.tr,
        style: moreStyle(),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width + moreHPad * 2;
  }
}

/// Chips packed into at most [maxLines] rows, with everything that does not fit
/// collapsing behind "More".
///
/// A [Wrap] cannot do this: it has no line budget, so it runs to whatever height
/// the content needs — which is how "Book Your Home Services" grew to four rows
/// of chips and pushed the folder grid down the page. This measures each chip
/// against the width it actually has, fills up to the budget, and reserves room
/// for "More" on the last line the moment anything is left over.
class _ChipLines extends StatelessWidget {
  const _ChipLines({
    required this.chips,
    required this.maxLines,
    this.onMore,
  });

  final List<DiscoverBannerChip> chips;
  final int maxLines;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final widths = [for (final chip in chips) _ChipMetrics.width(chip)];
        final moreWidth = _ChipMetrics.moreWidth() + _ChipMetrics.gap;

        final lines = <List<int>>[];
        var current = <int>[];
        var used = 0.0;
        var placed = 0;

        for (var i = 0; i < chips.length; i++) {
          final needed = (current.isEmpty ? 0 : _ChipMetrics.gap) + widths[i];
          final isLastLine = lines.length == maxLines - 1;
          final remaining = chips.length - i - 1;
          // On the final line, keep room for "More" whenever chips are still
          // waiting behind this one — otherwise the row fills to the edge and
          // the way to the rest of the section disappears.
          final budget =
              (isLastLine && remaining > 0) ? maxWidth - moreWidth : maxWidth;

          if (used + needed <= budget || current.isEmpty) {
            current.add(i);
            used += needed;
            placed++;
            continue;
          }
          lines.add(current);
          if (lines.length >= maxLines) {
            current = <int>[];
            break;
          }
          current = [i];
          used = widths[i];
          placed++;
        }
        if (current.isNotEmpty && lines.length < maxLines) lines.add(current);

        final hidden = chips.length - placed;
        final showMore = hidden > 0 && onMore != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var l = 0; l < lines.length; l++) ...[
              if (l > 0) const SizedBox(height: _ChipMetrics.gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < lines[l].length; c++) ...[
                    if (c > 0) const SizedBox(width: _ChipMetrics.gap),
                    _Chip(chip: chips[lines[l][c]]),
                  ],
                  if (showMore && l == lines.length - 1) ...[
                    const SizedBox(width: _ChipMetrics.gap),
                    _MoreChip(onTap: onMore!),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The round illustration at the head of the row.
class _LeadingPlate extends StatelessWidget {
  const _LeadingPlate({
    required this.icon,
    required this.fullBleed,
    this.onTap,
  });

  final String icon;

  /// True when the row supplied its OWN plate artwork ([leadingIcon]) rather
  /// than falling back to a category icon.
  ///
  /// The two want opposite treatment. A category icon is a small mark on
  /// nothing, so it needs the plate's grey ground and a pad to breathe inside
  /// it. The plate artwork is already a finished round badge WITH its own
  /// ground baked in, so padding it and fitting it `contain` draws the plate's
  /// circle, a ring of gap, then the image's circle — two rings where the
  /// design has one. Full-bleed `cover` lands the badge exactly on the plate.
  final bool fullBleed;

  final VoidCallback? onTap;

  /// 60x60, round — the specified size for the card's leading artwork.
  static const double _size = 60;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        padding: fullBleed ? EdgeInsets.zero : const EdgeInsets.all(7),
        decoration: const BoxDecoration(
          color: kDiscoverGlassPlateFill,
          shape: BoxShape.circle,
        ),
        // Clipped to the circle so a square illustration takes the plate's
        // shape instead of poking out of it at this size.
        child: ClipOval(
          child: _icon(icon, fit: fullBleed ? BoxFit.cover : BoxFit.contain),
        ),
      ),
    );
  }
}

/// A single category chip: artwork, then label.
class _Chip extends StatelessWidget {
  const _Chip({required this.chip});

  final DiscoverBannerChip chip;

  @override
  Widget build(BuildContext context) {
    final hasIcon = chip.icon.trim().isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: chip.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _ChipMetrics.hPad,
          vertical: _ChipMetrics.vPad,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_ChipMetrics.radius),
          border: Border.all(color: const Color(0xFFE3E9F2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon) ...[
              SizedBox(
                width: _ChipMetrics.iconSize,
                height: _ChipMetrics.iconSize,
                child: _icon(chip.icon),
              ),
              const SizedBox(width: _ChipMetrics.iconGap),
            ],
            Text(
              chip.label.tr,
              style: _ChipMetrics.labelStyle()
                  .copyWith(color: AppColors.secondaryTextColor),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// "More" — the way to everything the line budget could not fit.
class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _ChipMetrics.moreHPad,
          vertical: _ChipMetrics.vPad,
        ),
        child: Text(
          AppStrings.more.tr,
          // Same face and weight as the categories beside it, one size up and
          // in primary ink — enough to find at the end of a line of 10px
          // labels without turning into a button.
          style:
              _ChipMetrics.moreStyle().copyWith(color: AppColors.primaryColor),
          maxLines: 1,
        ),
      ),
    );
  }
}

/// "Need Money?  [Quick Apply For Loan]".
class _Cta extends StatelessWidget {
  const _Cta({required this.label, this.hint, this.onTap});

  final String label;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hint != null)
          CustomText(
            hint!,
            fontSize: SizeConfig.small11,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: CustomText(
              label,
              fontSize: SizeConfig.small11,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Category artwork, from the bundle or the API — Discover mixes both.
///
/// [fit] is `contain` for a category icon, which must sit whole inside whatever
/// slot it is given; the leading plate passes `cover` for its own purpose-drawn
/// artwork, which is meant to fill the circle edge to edge.
Widget _icon(String path, {BoxFit fit = BoxFit.contain}) {
  if (path.trim().isEmpty) {
    return const Icon(Icons.category_outlined,
        size: 14, color: AppColors.secondaryTextColor);
  }
  if (path.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: path,
      fit: fit,
      errorWidget: (_, __, ___) => const Icon(
        Icons.image_not_supported_outlined,
        size: 12,
        color: AppColors.secondaryTextColor,
      ),
    );
  }
  return LocalAssets(imagePath: path, boxFix: fit);
}
