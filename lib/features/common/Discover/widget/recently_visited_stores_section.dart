import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/widget/rounded_view_all_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Lightweight view model for a recently-visited store card. Populated from
/// placeholder data for now; swap [RecentlyVisitedStoresSection.stores] for a
/// controller-backed list once the endpoint is available.
class RecentStore {
  final String name;
  final String image;
  final String distance;
  final String categoryCount;
  final String productCount;
  final double rating;

  const RecentStore({
    required this.name,
    required this.image,
    required this.distance,
    required this.categoryCount,
    required this.productCount,
    required this.rating,
  });
}

/// Horizontally scrolling carousel of recently-visited store cards.
class RecentlyVisitedStoresSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  final void Function(RecentStore store)? onStoreTap;

  const RecentlyVisitedStoresSection({
    super.key,
    this.onViewAll,
    this.onStoreTap,
  });

  static final List<RecentStore> stores = [
    RecentStore(
      name: 'Gupta General Store',
      image: AppImageAssets.storefrontExterior,
      distance: '4.5Km Away',
      categoryCount: '10',
      productCount: '10K',
      rating: 4.8,
    ),
    RecentStore(
      name: 'Gupta General Store',
      image: AppImageAssets.interiorInsideShop,
      distance: '4.5Km Away',
      categoryCount: '10',
      productCount: '10K',
      rating: 4.8,
    ),
    RecentStore(
      name: 'Gupta General Store',
      image: AppImageAssets.productServiceDisplay,
      distance: '4.5Km Away',
      categoryCount: '10',
      productCount: '10K',
      rating: 4.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
        // color: AppColors.white,

      ),
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
                if (onViewAll != null) ViewAllButton(onTap: onViewAll!),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              itemCount: stores.length,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
              itemBuilder: (context, index) => _StoreCard(
                store: stores[index],
                onTap: () => onStoreTap?.call(stores[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final RecentStore store;
  final VoidCallback onTap;

  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.asset(
                    store.image,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                        const SizedBox(width: 2),
                        CustomText(
                          store.rating.toString(),
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
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.primaryColor,
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
                    store.name,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: 2),
                      CustomText(
                        store.distance,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.grid_view_rounded,
                          value: store.categoryCount,
                          label: 'Category',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.inventory_2_outlined,
                          value: store.productCount,
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

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
