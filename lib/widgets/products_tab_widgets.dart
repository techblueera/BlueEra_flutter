import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// The shared building blocks of the **Products tab** every me-section
/// merchant home renders — grocery, food, product, manufacturer and
/// automotive parts.
///
/// The tab reads top-to-bottom as: gradient masthead (what this tab is + the
/// primary add action) → top-selling rail → category rail. Each service keeps
/// its own data sources, card widgets and routing; only the chrome around them
/// lives here, so the five screens stay visually identical without five copies
/// of the same decoration.
///
/// **Layout contract:** every host wraps its tab body in a scroll view padded
/// `left: 20` and nothing on the right, so these widgets own their own trailing
/// inset ([productsTabTrailingInset]) and rails deliberately bleed off the
/// right edge.

/// Right-hand inset the tab's scroll padding does NOT provide.
double get productsTabTrailingInset => SizeConfig.size20;

/// Masthead gradient per service — one hue family each, so the five Products
/// tabs share a layout without reading as the same screen when a merchant
/// switches between services.
///
/// Every ramp goes mid-tone → lighter along the same diagonal, which keeps the
/// white title, helper line and add pill legible on all of them. Pick from
/// here rather than passing ad-hoc colours, so a service's identity stays in
/// one place.
class ProductsBannerGradient {
  const ProductsBannerGradient._();

  static const LinearGradient _base = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2E8BE0), Color(0xFF7FD6CE)],
  );

  /// Blue → teal. The original masthead; the warm-cool shift keeps it from
  /// reading as another flat brand-blue block.
  static const LinearGradient grocery = _base;

  /// Orange → amber. Appetite colours, the one place in the app they belong.
  static const LinearGradient food = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEF6C2B), Color(0xFFF9B233)],
  );

  /// Violet → orchid — general retail.
  static const LinearGradient product = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6A3DE8), Color(0xFFB57BEE)],
  );

  /// Emerald → mint — production/supply.
  static const LinearGradient manufacturer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0E8A6A), Color(0xFF6FD1A6)],
  );

  /// Crimson → coral — motor trade.
  static const LinearGradient automotive = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA32235), Color(0xFFE2685C)],
  );

  /// Indigo → periwinkle — pharmacy/medical.
  static const LinearGradient medical = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3730A3), Color(0xFF818CF8)],
  );
}

/// Gradient masthead for the Products tab: what this tab is, plus the primary
/// action. Sits above every other section, so the tab opens with a header
/// rather than a floating CTA.
///
/// Left padding comes from the host's scroll view; only the right edge is set
/// here.
class ProductsTabBanner extends StatelessWidget {
  /// Section name — the services all pass their "Products" tab label.
  final String title;

  /// One-line helper under the title.
  final String subtitle;

  /// Label on the add pill ("Add Grocery", "Add Food", "Add Product", …).
  final String ctaLabel;

  final VoidCallback onAdd;

  /// The service's own ramp — pick one from [ProductsBannerGradient] rather
  /// than building a gradient here, so no two services end up sharing a look.
  final LinearGradient gradient;

  const ProductsTabBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onAdd,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          right: productsTabTrailingInset, top: SizeConfig.size4),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size10,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: SizeConfig.size36,
            height: SizeConfig.size36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            // The app's own cart asset rather than a Material glyph, so the
            // banner matches the icon language used elsewhere in the store.
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size8),
              child: LocalAssets(
                imagePath: AppIconAssets.productCartIcon,
                imgColor: Colors.white,
                boxFix: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  title,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                CustomText(
                  subtitle,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          _BannerAddCta(label: ctaLabel, onTap: onAdd),
        ],
      ),
    );
  }
}

class _BannerAddCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BannerAddCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          decoration: BoxDecoration(
            // Slight white fill plus a white hairline — enough to read as a
            // button against the gradient without competing with the title.
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: Colors.white),
              SizedBox(width: SizeConfig.size4),
              CustomText(
                label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared header for every Products-tab section: a large title with an
/// optional helper line beneath and a single action on the right.
///
/// There is deliberately no vertical brand-accent bar — with each section
/// already separated by whitespace it was decoration rather than structure,
/// and it competed with the section's own action for attention.
/// [subtitle] is optional: the categories header is a title alone, so a blank
/// helper line there would just add dead space.
class ProductsSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const ProductsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: productsTabTrailingInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  title,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    subtitle!,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if(action!=null)...[
            SizedBox(width: SizeConfig.size8),
            action!,
          ]
        ],
      ),
    );
  }
}

/// "View All" pill — a soft brand-tinted fill instead of an outlined chip with
/// a solid circular badge. One weight of emphasis, not two.
class ProductsViewAllPill extends StatelessWidget {
  final VoidCallback onTap;

  /// Defaults to the shared "View All" string.
  final String? label;

  const ProductsViewAllPill({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              label ?? AppStrings.viewAll.tr,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size4),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }
}

/// Square icon-only button that balances the "View All" pill above it — the
/// categories section's action. Opens the add-products flow.
class ProductsAddSquareCta extends StatelessWidget {
  final VoidCallback onTap;

  const ProductsAddSquareCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: SizeConfig.size36,
        height: SizeConfig.size36,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.arrow_forward_rounded,
            size: 20, color: AppColors.primaryColor),
      ),
    );
  }
}

/// Horizontal scroller every Products-tab section uses for its content.
///
/// No white shell — the cards are the surface, sitting directly on the page
/// background so the rail reads as one shelf. Trailing inset only, so the last
/// card clears the edge while the rail still bleeds off the right.
class ProductsRail extends StatelessWidget {
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Gap between cards.
  final double spacing;

  const ProductsRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        padding: EdgeInsets.only(right: productsTabTrailingInset),
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: spacing),
          child: itemBuilder(context, index),
        ),
      ),
    );
  }
}

/// Fixed-height loading state for a [ProductsRail], so the section holds its
/// place instead of collapsing while the first fetch is in flight.
class ProductsRailLoader extends StatelessWidget {
  final double height;

  const ProductsRailLoader({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

/// One tile in the category rail: image-led with a small caption underneath.
///
/// Compact rail item, not a grid cell. The image sits straight on the card's
/// white — no tinted well, because at this size a second surface just eats the
/// image's room — and there's no chevron badge: in a horizontal lane the whole
/// tile reads as tappable, so the affordance was noise.
class ProductCategoryTile extends StatelessWidget {
  /// Network URL or bundled asset path; empty renders the placeholder.
  final String? image;
  final String? name;
  final VoidCallback onTap;

  const ProductCategoryTile({
    super.key,
    required this.image,
    required this.name,
    required this.onTap,
  });

  /// Height of the rail these tiles sit in.
  static const double railHeight = 86;
  static const double tileWidth = 88;

  @override
  Widget build(BuildContext context) {
    final img = image ?? '';
    final hasImage = img.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: tileWidth,
        padding: EdgeInsets.all(SizeConfig.size6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDF0F5), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _image(img, hasImage: hasImage),
              ),
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              name ?? '',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Category art comes in three flavours across the services: a bundled
  /// asset, a raster URL, and — medical's catalogue — a remote **SVG**, which
  /// [CachedNetworkImage] cannot decode, so it gets its own branch.
  /// ([LocalAssets] already handles bundled SVGs itself.)
  Widget _image(String img, {required bool hasImage}) {
    if (!hasImage) {
      return LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        boxFix: BoxFit.contain,
      );
    }
    if (!isNetworkImage(img)) {
      return LocalAssets(imagePath: img, boxFix: BoxFit.contain);
    }
    if (img.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        img,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: img,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => Icon(
        Icons.broken_image,
        size: 20,
        color: Colors.grey,
      ),
    );
  }
}

/// Shimmer stand-in for the category rail. Screens that expose a "categories
/// still loading" flag show this instead of the empty state, so a slow fetch
/// never reads as "you have no products".
class ProductCategoryRailSkeleton extends StatelessWidget {
  const ProductCategoryRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductsRail(
      height: ProductCategoryTile.railHeight,
      itemCount: 5,
      spacing: SizeConfig.size8,
      itemBuilder: (_, __) => buildLoadingShimmer(
        child: shimmerContainer(
          width: ProductCategoryTile.tileWidth,
          height: ProductCategoryTile.railHeight,
        ),
      ),
    );
  }
}
