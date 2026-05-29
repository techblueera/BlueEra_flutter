import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/rental/controller/property_dashboard_controller.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/view/property_details_screen.dart';
import 'package:BlueEra/features/common/rental/widget/list_your_property_screen.dart';
import 'package:BlueEra/features/common/rental/widget/property_listing_card.dart';
import 'package:BlueEra/features/common/rental/widget/rent/list_your_rent_property_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';

class RentalServicesDashboardScreenV2 extends StatelessWidget {
  const RentalServicesDashboardScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PropertyDashboardController());

    return Scaffold(
      appBar: CommonBackAppBar(
        title: AppStrings.myListing.tr,
        isShadowShow: false,
        showElevation: 0,
        buildCustomActionWidget: () => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => _showAddSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                    AppStrings.addListing.tr,
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F9FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                label: '${AppStrings.forSell.tr} (${ctrl.sellCount.value})',
                icon: Icons.handshake_rounded,
                isSelected: ctrl.selectedTab.value == 0,
                onTap: () => ctrl.switchTab(0),
              ),
            ),
            Expanded(
              child: _tabButton(
                label: '${AppStrings.forRent.tr} (${ctrl.rentCount.value})',
                icon: Icons.vpn_key_rounded,
                isSelected: ctrl.selectedTab.value == 1,
                onTap: () => ctrl.switchTab(1),
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : const Color(0xFFF2F9FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.secondaryTextColor),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(PropertyDashboardController ctrl) {
    final categories = ctrl.selectedTab.value == 0 ? ctrl.sellCategories : ctrl.rentCategories;

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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primaryColor : AppColors.secondaryTextColor,
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
    final categories = ctrl.selectedTab.value == 0 ? ctrl.sellCategories : ctrl.rentCategories;

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
                size: 48, color: AppColors.primaryColor.withValues(alpha: 0.4)),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              AppStrings.noPropertiesFound.tr,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.tapAddListingToListYourProperty.tr,
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

  Widget _propertyCard(PropertyModel property) {
    return PropertyListingCard(
      property: property,
      isOwner: true,
      onTap: () => Get.to(() => PropertyDetailsScreen(property: property)),
      onDeleted: () {
        final ctrl = Get.find<PropertyDashboardController>();
        ctrl.refresh();
      },
    );
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
                        AppStrings.listYourProperty.tr,
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
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF505050)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    AppStrings.chooseHowYouWantToList.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                _addTile(
                  icon: Icons.sell_rounded,
                  label: AppStrings.forSell.tr,
                  subtitle: AppStrings.sellHousesPlotsShopsMore.tr,
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
                  label: AppStrings.forRent.tr,
                  subtitle: AppStrings.rentOutHousesOfficesSpaces.tr,
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

class _CategoryIconTileState extends State<_CategoryIconTile> with SingleTickerProviderStateMixin {
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
                    fontSize: SizeConfig.large, fontWeight: FontWeight.w700, color: AppColors.mainTextColor),
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
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ),
        ],
      ),
    ),
  );
}
