import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/model/associated_shops_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "My Store" tab — shows rider's associated shops from API.
/// Calls GET /riders/associations/shops with filter support.
class RiderMyStoreTab extends StatefulWidget {
  const RiderMyStoreTab({super.key});

  @override
  State<RiderMyStoreTab> createState() => _RiderMyStoreTabState();
}

class _RiderMyStoreTabState extends State<RiderMyStoreTab> {
  final controller = getOrPut(() => DeliveryPartnerController());
  final ScrollController _scrollController = ScrollController();

  int _selectedFilterIndex = 0;

  static const List<_FilterOption> _filters = [
    _FilterOption(label: 'All Stores', icon: Icons.storefront_outlined, value: 'all'),
    _FilterOption(label: 'Grocery', icon: Icons.shopping_basket_outlined, value: 'grocery'),
    _FilterOption(label: 'Health Care', icon: Icons.local_hospital_outlined, value: 'healthcare'),
  ];

  static const List<Color> _cardColors = [
    Color(0xFFFFFEF7),
    Color(0xFFFFF9F3),
    Color(0xFFFFF5F5),
  ];

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchShops() {
    controller.getAssociatedShops(filter: _filters[_selectedFilterIndex].value);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.getAssociatedShops(
        filter: _filters[_selectedFilterIndex].value,
        isLoadMore: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterSidebar(),
        SizedBox(width: SizeConfig.size6),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: _buildShopList(),
        )),
      ],
    );
  }

  // ─── Left sidebar (filter) ─────────────────────────────────────

  Widget _buildFilterSidebar() {
    return Container(
      width: SizeConfig.screenWidth * 0.18,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: _filters.length,
        padding: EdgeInsets.only(bottom: SizeConfig.size30),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final selected = _selectedFilterIndex == index;

          return InkWell(
            onTap: () {
              if (_selectedFilterIndex == index) return;
              setState(() => _selectedFilterIndex = index);
              _fetchShops();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: selected ? 10 : 6, horizontal: 4),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.skyBlueE4,
                            AppColors.skyBlueE4.withValues(alpha: 0.3),
                          ],
                        )
                      : null,
                  border: selected
                      ? const Border(
                          left: BorderSide(
                            color: AppColors.primaryColor,
                            width: 3,
                          ),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.all(6),
                      height: selected ? 60 : 50,
                      width: selected ? 60 : 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? null : AppColors.skyBlueE4,
                      ),
                      child: Icon(
                        filter.icon,
                        size: selected ? 28 : 22,
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      style: TextStyle(
                        fontSize: selected ? 11 : 10,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.mainTextColor
                            : AppColors.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                      child: Text(filter.label, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Right content ─────────────────────────────────────────────

  Widget _buildShopList() {
    return Obx(() {
      final shops = controller.associatedShops;
      final isLoading = controller.isAssociatedShopsLoading.value;

      // Loading (first load)
      if (isLoading && shops.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // Empty
      if (!isLoading && shops.isEmpty) {
        return const Center(
          child: EmptyStateWidget(message: 'No associated stores yet'),
        );
      }

      // List
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,

              itemCount: shops.length,
              padding: EdgeInsets.only(
                top: SizeConfig.paddingM,
                bottom: SizeConfig.paddingL,
                right: SizeConfig.paddingXS,
              ),
              itemBuilder: (_, index) {
                final shop = shops[index];
                final bgColor = _cardColors[index % _cardColors.length];
                return _AssociatedShopCard(shop: shop, bgColor: bgColor);
              },
            ),
          ),
        ],
      );
    });
  }

}

// ═══════════════════════════════════════════════════════════════════
//  ASSOCIATED SHOP CARD
// ═══════════════════════════════════════════════════════════════════

class _AssociatedShopCard extends StatelessWidget {
  final AssociatedShop shop;
  final Color bgColor;

  const _AssociatedShopCard({required this.shop, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    final biz = shop.business;
    if (biz == null) return const SizedBox.shrink();

    final categoryName = biz.categoryOfBusiness?.name ?? AppStrings.na;
    final totalProducts = shop.grocery?.totalProducts ?? 0;
    final parentCategories = shop.grocery?.parentCategories ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bgColor,
        border: Border.all(color: AppColors.greyE5, width: 0.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: Logo + Name + Badges ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedAvatarWidget(
                  imageUrl: biz.logo ?? '',
                  size: SizeConfig.size40,
                  borderColor: Colors.white,
                  borderRadius: SizeConfig.size20,
                ),
                SizedBox(width: SizeConfig.size8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        biz.businessName ?? 'Unknown Business',
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          _ratingBadge('${biz.avgRating ?? 0}'),
                          const SizedBox(width: 6),
                          _categoryBadge(categoryName),
                          if (biz.businessIsVerified == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified,
                                size: 14, color: AppColors.primaryColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: SizeConfig.paddingXSL),

            // ─── Address & Distance ───
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.greyE5, width: 0.5),
                color: AppColors.white,
              ),
              child: Row(
                children: [
                  _iconContainer(AppIconAssets.location_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shop.distance != null)
                          CustomText(
                            '${shop.distance} Away',
                            fontSize: 13,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          biz.address ?? biz.cityStatePincode ?? AppStrings.na,
                          fontSize: 11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.size6),

            // ─── Stats: Categories & Products ───
            Row(
              children: [
                _statBox(
                  icon: AppIconAssets.staggeredIcon,
                  count: '${parentCategories.length}',
                  label: 'Category',
                  iconColor: const Color(0xFF9964F4),
                  statBgColor: AppColors.purpleFD,
                ),
                SizedBox(width: SizeConfig.size6),
                _statBox(
                  icon: AppIconAssets.productCartIcon,
                  count: '$totalProducts',
                  label: 'Product',
                  iconColor: const Color(0xFF6179CD),
                  statBgColor: AppColors.purpleFF,
                ),
              ],
            ),

            // ─── Category chips (from grocery data) ───
            if (parentCategories.isNotEmpty) ...[
              SizedBox(height: SizeConfig.size8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: parentCategories.take(5).map((pc) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.fillColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5, width: 0.5),
                    ),
                    child: CustomText(
                      '${pc.category?.name ?? ''} (${pc.count ?? 0})',
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  Widget _ratingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.lightYellowShade,
        border: Border.all(color: AppColors.lightYellowShade, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalAssets(imagePath: AppIconAssets.star, height: 12, width: 12),
          const SizedBox(width: 4),
          CustomText(rating,
              fontSize: 10,
              color: AppColors.blue2D,
              fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _categoryBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.greenCB,
        border: Border.all(color: AppColors.greenCB, width: 0.5),
      ),
      child: CustomText(text,
          fontSize: 10, color: AppColors.green2C, fontWeight: FontWeight.w400),
    );
  }

  Widget _statBox({
    required String icon,
    required String count,
    required String label,
    required Color iconColor,
    required Color statBgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: statBgColor,
                  borderRadius: BorderRadius.circular(6)),
              child: LocalAssets(
                  imagePath: icon,
                  imgColor: iconColor,
                  height: 18,
                  width: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(count,
                      fontSize: SizeConfig.medium,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w600),
                  CustomText(label,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconContainer(String iconPath) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: LocalAssets(
        imagePath: iconPath,
        imgColor: AppColors.secondaryTextColor,
        height: 24,
        width: 20,
      ),
    );
  }
}

// ─── Filter option model ─────────────────────────────────────────

class _FilterOption {
  final String label;
  final IconData icon;
  final String value;
  const _FilterOption(
      {required this.label, required this.icon, required this.value});
}
