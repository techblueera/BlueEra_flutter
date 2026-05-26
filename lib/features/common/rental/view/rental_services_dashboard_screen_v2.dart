import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/rental/controller/property_dashboard_controller.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/features/common/rental/widget/list_your_property_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rent/list_your_rent_property_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalServicesDashboardScreenV2 extends StatelessWidget {
  const RentalServicesDashboardScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PropertyDashboardController());

    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'My Listing',
        isShadowShow: false,
        showElevation: 0,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => _showAddSheet(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  CustomText(
                    'Add Listing',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomWidget: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFDDE2EE)),
        ),
      ),
      body: Obx(() {
        if (ctrl.isStatsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Touch all reactive values so this Obx rebuilds on any change.
        ctrl.selectedTab.value;
        ctrl.selectedCategoryIndex.value;
        ctrl.sellCount.value;
        ctrl.rentCount.value;
        ctrl.isLoading.value;
        ctrl.properties.length;

        return Column(
          children: [
            _buildTabs(ctrl),
            _buildCategoryChips(ctrl),
            Expanded(child: _buildPropertyList(ctrl)),
          ],
        );
      }),
    );
  }

  Widget _buildTabs(PropertyDashboardController ctrl) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size14,
        vertical: SizeConfig.size10,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'For Sell (${ctrl.sellCount.value})',
              icon: Icons.sell_rounded,
              isSelected: ctrl.selectedTab.value == 0,
              onTap: () => ctrl.switchTab(0),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: _tabButton(
              label: 'For Rent (${ctrl.rentCount.value})',
              icon: Icons.vpn_key_rounded,
              isSelected: ctrl.selectedTab.value == 1,
              onTap: () => ctrl.switchTab(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : const Color(0xFFDDE2EE),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.secondaryTextColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(PropertyDashboardController ctrl) {
      final categories = ctrl.selectedTab.value == 0
          ? ctrl.sellCategories
          : ctrl.rentCategories;

      if (categories.isEmpty) return const SizedBox.shrink();

      final tabKey = ctrl.selectedTab.value;
      return Container(
        key: ValueKey('chips_$tabKey'),
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
          itemCount: categories.length,
          separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
          itemBuilder: (_, i) {
            final cat = categories[i];
            final selected = ctrl.selectedCategoryIndex.value == i;

            return GestureDetector(
              key: ValueKey('${tabKey}_${cat.key}'),
              onTap: () => ctrl.selectCategory(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: SizeConfig.size65,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CategoryIconTile(
                      isActive: selected,
                      child: LocalAssets(
                        imagePath: cat.image,
                        width: 30,
                        height: 30,
                        boxFix: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size4),
                    SizedBox(
                      height: 28,
                      child: CustomText(
                        cat.label,
                        fontSize: SizeConfig.extraSmall,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
  }

  Widget _buildPropertyList(PropertyDashboardController ctrl) {
    final categories = ctrl.selectedTab.value == 0
        ? ctrl.sellCategories
        : ctrl.rentCategories;

    if (categories.isEmpty) return _buildEmpty();

    if (ctrl.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ctrl.properties.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: ctrl.refresh,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size14,
          SizeConfig.size8,
          SizeConfig.size14,
          SizeConfig.size24,
        ),
        itemCount: ctrl.properties.length,
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (_, i) => _propertyCard(ctrl.properties[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.holiday_village_outlined,
                size: 48,
                color: AppColors.primaryColor.withValues(alpha: 0.4)),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              'No properties found',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              'Tap "Add Listing" to list your property',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyCard(dynamic property) {
    final String name = property['propertyName'] ?? '';
    final num price = property['price'] ?? 0;
    final String type = property['propertyType'] ?? '';
    final double rating = (property['rating'] ?? 0).toDouble();
    final List images = property['propertyImages'] ?? [];
    final String listingType = property['listingType'] ?? '';

    String location = '';
    String details = '';

    final ha = property['houseAndApartment'];
    final lp = property['landAndPlots'];
    final so = property['shopAndOffices'];
    final np = property['newProjectsAndProperties'];
    final pg = property['pgAndGuestHouse'];

    if (ha != null) {
      location = ha['propertyLocation'] ?? '';
      final parts = <String>[
        if (ha['bhk'] != null) '${ha['bhk']} BHK House',
        if (ha['areaDetails'] != null &&
            ha['areaDetails'].toString().isNotEmpty)
          ha['areaDetails'],
        if (ha['bathrooms'] != null) '${ha['bathrooms']} Bathroom',
        if (ha['totalFloors'] != null) '${ha['totalFloors']} Floors',
      ];
      details = parts.join(' • ');
    } else if (lp != null) {
      location = lp['propertyLocation'] ?? '';
      final plot = lp['plotAreaDetails'];
      final parts = <String>[
        if (plot != null && plot['totalArea'] != null) plot['totalArea'],
        if (plot != null && plot['length'] != null)
          'L: ${plot['length']}',
        if (plot != null && plot['breadth'] != null)
          'B: ${plot['breadth']}',
      ];
      details = parts.join(' • ');
    } else if (so != null) {
      location = so['propertyLocation'] ?? '';
      final parts = <String>[
        if (so['furnishing'] != null) so['furnishing'],
        if (so['superBuiltupArea'] != null) so['superBuiltupArea'],
        if (so['washrooms'] != null) '${so['washrooms']} Washroom',
        if (so['carParkings'] != null) '${so['carParkings']} Parking',
      ];
      details = parts.join(' • ');
    } else if (np != null) {
      location = np['propertyLocation'] ?? '';
      final parts = <String>[
        if (np['typeOfProperty'] != null) np['typeOfProperty'],
        if (np['area'] != null) np['area'],
        if (np['noOfTowers'] != null) '${np['noOfTowers']} Towers',
        if (np['noOfFloors'] != null) '${np['noOfFloors']} Floors',
      ];
      details = parts.join(' • ');
    } else if (pg != null) {
      location = pg['propertyLocation'] ?? '';
      final parts = <String>[
        if (pg['subType'] != null) pg['subType'],
        if (pg['roomType'] != null) pg['roomType'],
        if (pg['furnishing'] != null) pg['furnishing'],
      ];
      details = parts.join(' • ');
    }

    final typeLabel = _typeLabel(type);

    String priceStr;
    final priceRange = property['priceRange'];
    final hasRange = priceRange != null &&
        priceRange is Map &&
        (priceRange['min'] ?? 0) > 0;
    if (hasRange) {
      final minP = _formatIndianPrice(priceRange['min'] ?? 0);
      final maxP = _formatIndianPrice(priceRange['max'] ?? 0);
      priceStr = '₹$minP - ₹$maxP';
      if (listingType == 'Rent') priceStr += '/mo';
    } else {
      priceStr = listingType == 'Rent'
          ? '₹${_formatIndianPrice(price)}/mo'
          : '₹${_formatIndianPrice(price)}';
    }

    final imageCount = images.length;
    final radius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(() => PropertyDetailsScreen(property: property)),
        borderRadius: radius,
        child: Column(
          children: [
            Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12)),
                        child: SizedBox(
                          width: 130,
                          height: 150,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              images.isNotEmpty
                                  ? Image.network(
                                      images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(),
                                    )
                                  : _placeholder(),
                              if (imageCount > 1)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.mainTextColor
                                          .withValues(alpha: 0.75),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: CustomText(
                                      '+${imageCount - 1}',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      name,
                                      fontSize: SizeConfig.medium15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.mainTextColor,
                                      maxLines: 1,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Icon(Icons.more_vert,
                                        size: 18,
                                        color:
                                            AppColors.secondaryTextColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14,
                                      color: AppColors.rating),
                                  const SizedBox(width: 3),
                                  CustomText(
                                    rating.toStringAsFixed(1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                      color: AppColors.mainTextColor,
                                    ),
                                    const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors
                                            .secondaryTextColor
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: CustomText(
                                      typeLabel,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          AppColors.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const _DashedDivider(),
                              const SizedBox(height: 6),
                              CustomText(
                                priceStr,
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w800,
                                color: AppColors.mainTextColor,
                              ),
                              if (details.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                CustomText(
                                  details,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondaryTextColor,
                                  maxLines: 2,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            if (location.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.secondaryTextColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: CustomText(
                        location,
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.holiday_village_outlined,
            size: 36,
            color: AppColors.primaryColor.withValues(alpha: 0.3)),
      ),
    );
  }

  String _formatIndianPrice(num price) {
    final str = price.toInt().toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formatted = rest.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '$formatted,$last3';
  }

  String _typeLabel(String type) {
    const labels = {
      'HouseAndApartment': 'House & Apartment',
      'LandAndPlots': 'Land & Plots',
      'ShopAndOffices': 'Shop & Offices',
      'NewProjectsAndProperties': 'New Projects',
      'PGAndGuestHouse': 'PG & Guest House',
    };
    return labels[type] ?? type;
  }

  void _showAddSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size20,
              SizeConfig.size12,
              SizeConfig.size20,
              SizeConfig.size20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE2EE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: SizeConfig.size12),
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        'List Your Property',
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF4F6FA),
                          border: Border.all(color: const Color(0xFFDDE2EE)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF505050)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    'Choose how you want to list',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                _addTile(
                  icon: Icons.sell_rounded,
                  label: 'For Sale',
                  subtitle: 'Sell houses, plots, shops & more',
                  color: const Color(0xFF0086FF),
                  bg: const Color(0xFFEBF5FF),
                  onTap: () {
                    Get.back();
                    Get.to(() => const ListYourPropertyScreen());
                  },
                ),
                SizedBox(height: SizeConfig.size12),
                _addTile(
                  icon: Icons.vpn_key_rounded,
                  label: 'For Rent',
                  subtitle: 'Rent out houses, offices & spaces',
                  color: const Color(0xFF00B87A),
                  bg: const Color(0xFFE6FAF3),
                  onTap: () {
                    Get.back();
                    Get.to(() => const ListYourRentPropertyScreen());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _CategoryIconTile extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const _CategoryIconTile({
    required this.isActive,
    required this.child,
  });

  @override
  State<_CategoryIconTile> createState() => _CategoryIconTileState();
}

class _CategoryIconTileState extends State<_CategoryIconTile>
    with SingleTickerProviderStateMixin {
  static const List<RadialGradient> _gradients = <RadialGradient>[
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFC9FFB7), Color(0xFF0DA217), Color(0xFF04650B)],
    ),
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFC0FFF9), Color(0xFF12CEBB), Color(0xFF018D7F)],
    ),
    RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Color(0xFFE1B6FF), Color(0xFF7D0CCD), Color(0xFF3D0366)],
    ),
  ];

  late final AnimationController _ctl;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _index = (_index + 1) % _gradients.length);
          _ctl.forward(from: 0);
        }
      });
    if (widget.isActive) _ctl.forward();
  }

  @override
  void didUpdateWidget(covariant _CategoryIconTile old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctl.isAnimating) {
      _ctl.forward();
    } else if (!widget.isActive && _ctl.isAnimating) {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = SizeConfig.size48;
    if (!widget.isActive) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: widget.child,
      );
    }
    final safeIndex = _index % _gradients.length;
    final from = _gradients[safeIndex];
    final to = _gradients[(safeIndex + 1) % _gradients.length];
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, child) {
        final g = RadialGradient.lerp(from, to, _ctl.value) ?? from;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D00294E),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final count =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondaryTextColor.withValues(alpha: 0.25),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

Widget _addTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(label,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor),
                  const SizedBox(height: 3),
                  CustomText(subtitle,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child:
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }
