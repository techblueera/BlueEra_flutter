import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/controller/recent_shops_controller.dart';
import 'package:BlueEra/features/common/Discover/model/recent_shops_models.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Horizontally scrolling carousel of the user's recently-visited stores
/// ("order again"). Backed by [RecentShopsController], which compiles the
/// grocery / product / food `recent-shops` endpoints. Hidden entirely when the
/// user has no recent shops. See docs/backend/RECENT_SHOPS_FLUTTER_INTEGRATION.md.
class RecentlyVisitedStoresSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final void Function(RecentShop store)? onStoreTap;

  const RecentlyVisitedStoresSection({
    super.key,
    this.onViewAll,
    this.onStoreTap,
  });

  @override
  State<RecentlyVisitedStoresSection> createState() =>
      _RecentlyVisitedStoresSectionState();
}

class _RecentlyVisitedStoresSectionState
    extends State<RecentlyVisitedStoresSection> {
  final _controller = getOrPut(() => RecentShopsController());

  @override
  void initState() {
    super.initState();
    _controller.fetchIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = _controller.isLoading.value && _controller.shops.isEmpty;
      final shops = _controller.shops;

      // Loaded with nothing → hide the section (no empty card).
      if (_controller.loaded.value && !loading && shops.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      'Recently Visited Stores',
                      fontSize: SizeConfig.large18,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.onViewAll != null)
                    ViewAllButton(onTap: widget.onViewAll!),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            SizedBox(
              height: 230,
              child: loading
                  ? _loadingRow()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      itemCount: shops.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: SizeConfig.size12),
                      itemBuilder: (context, index) => _StoreCard(
                        shop: shops[index],
                        onTap: () => widget.onStoreTap?.call(shops[index]),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _loadingRow() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
      itemBuilder: (_, __) => _shimmerCard(),
    );
  }

  /// Store-card shaped shimmer skeleton (image block + name/location lines + two
  /// stat chips). A transparent outer box so only the grey shapes shimmer, with
  /// gaps between them.
  Widget _shimmerCard() {
    return buildLoadingShimmer(
      child: SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shimmerContainer(height: 120, width: 190, radius: 14),
            const SizedBox(height: 10),
            shimmerContainer(height: 14, width: 120, radius: 4),
            const SizedBox(height: 8),
            shimmerContainer(height: 10, width: 90, radius: 4),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: shimmerContainer(height: 26, radius: 6)),
                const SizedBox(width: 6),
                Expanded(child: shimmerContainer(height: 26, radius: 6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final RecentShop shop;
  final VoidCallback onTap;

  const _StoreCard({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final biz = shop.business;
    final logo = biz?.logo ?? '';
    final location = (biz?.cityStatePincode?.isNotEmpty ?? false)
        ? biz!.cityStatePincode!
        : (biz?.address ?? '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: logo,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imageFallback(),
                          errorWidget: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                if (biz?.avgRating != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFB300), size: 14),
                          const SizedBox(width: 2),
                          CustomText(
                            biz!.avgRating!.toStringAsFixed(1),
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.chat,
                      height: 16,
                      width: 16,
                      imgColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    shop.displayName,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.primaryColor),
                        const SizedBox(width: 2),
                        Expanded(
                          child: CustomText(
                            location,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.receipt_long_outlined,
                          value: '${shop.orderCount}',
                          label: 'Orders',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.inventory_2_outlined,
                          value: '${shop.distinctProducts}',
                          label: 'Products',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        height: 120,
        width: double.infinity,
        color: AppColors.lightBlue,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_outlined,
            size: 36, color: AppColors.primaryColor),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondaryTextColor),
          const SizedBox(width: 4),
          CustomText(
            value,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
